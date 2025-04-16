param(
    [Parameter(Mandatory = $false)]
    [string]$RepoListPath = "${PSScriptRoot}\repos\repo-list.txt",

    [Parameter(Mandatory = $false)]
    [string]$WorkDir = "${PSScriptRoot}\repos"
)

# load functions
. "${PSScriptRoot}\scripts\Config.ps1"
. "${PSScriptRoot}\scripts\DownloadRepoGit.ps1"
. "${PSScriptRoot}\scripts\RunSecScan.ps1"

# Create working directory if it does not exist
if (-not (Test-Path $WorkDir)) {
    New-Item -Path $WorkDir -ItemType Directory | Out-Null
}

# Read entries from file format: ProjectName | URL
$repoEntries = Get-Content $RepoListPath | Where-Object { $_ -match '\|' }

# Phase 1: Cloning of all repositories
foreach ($entry in $repoEntries) {
    try {
        $parts = $entry -split '\|'
        $solutionName = $parts[0].Trim() -replace '[^\w\-]', '_'
        $url = $parts[1].Trim()

        $repoFolderName = [System.IO.Path]::GetFileNameWithoutExtension($url) -replace '[^\w\-]', '_'
        $repoPath = Join-Path $WorkDir $repoFolderName

        Write-Host "Cloning solution '${solutionName}' from ${url}..." -ForegroundColor Cyan

        if (-not (Test-Path $repoPath)) {
            DownloadRepoGit -UrlGit $url -Dest $repoPath
        }
        else {
            Write-Host "Repository already exists: ${repoPath}, omitting cloning." -ForegroundColor Green
        }

    }
    catch {
        Write-Error "Error cloning ${entry}: $_"
    }
}

# Phase 2: Execute the scans
foreach ($entry in $repoEntries) {
    try {
        $parts = $entry -split '\|'
        $solutionName = $parts[0].Trim() -replace '[^\w\-]', '_'
        $url = $parts[1].Trim()

        $repoFolderName = [System.IO.Path]::GetFileNameWithoutExtension($url) -replace '[^\w\-]', '_'
        $repoPath = Join-Path $WorkDir $repoFolderName
        $reportPath = Join-Path "${WorkDir}" "${solutionName}.csv"

        if (Test-Path $reportPath) {
            Write-Host "Reporte ya existe para '${solutionName}', omitiendo escaneo." -ForegroundColor Green
            continue
        }

        Write-Host "Scanning solution '${solutionName}' in ${repoPath}..." -ForegroundColor Cyan

        RunSecScan -ProjectName $solutionName -ProjectPath $repoPath -WorkDir $WorkDir
    }
    catch {
        Write-Error "Scanning error ${entry}: $_"
    }
}
