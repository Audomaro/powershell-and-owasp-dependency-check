param(
    [Parameter(Mandatory = $false)]
    [string]$RepoListPath = "${PSScriptRoot}\repos\repo-list.txt",

    [Parameter(Mandatory = $false)]
    [string]$WorkDir = "${PSScriptRoot}\repos"
)

# Load functions from an external script located in the "scripts" folder
. "${PSScriptRoot}\scripts\Config.ps1"
. "${PSScriptRoot}\scripts\DownloadRepoGit.ps1"
. "${PSScriptRoot}\scripts\RunSecScan.ps1"
. "${PSScriptRoot}\scripts\InstallNpmDependencies.ps1"
. "${PSScriptRoot}\scripts\InstallNugetPackages.ps1"

# Create working directory if it does not exist
if (-not (Test-Path $WorkDir)) {
    New-Item -Path $WorkDir -ItemType Directory | Out-Null
}

# Read entries from file format: ProjectName | URL
$repoEntries = Get-Content $RepoListPath | Where-Object { $_ -match '\|' }

# Phase 1: Cloning of all repositories
Write-Host "=========================> Phase 1: Cloning of all repositories" -ForegroundColor $Env:COLOR_INFO
foreach ($entry in $repoEntries) {
    try {
        $parts = $entry -split '\|'
        $solutionName = $parts[0].Trim() -replace '[^\w\-]', '_'
        $url = $parts[1].Trim()

        $repoFolderName = [System.IO.Path]::GetFileNameWithoutExtension($url) -replace '[^\w\-]', '_'
        $repoPath = Join-Path $WorkDir $repoFolderName

        Write-Host "Cloning solution '${solutionName}' from ${url}..." -ForegroundColor $Env:COLOR_INFO

        if (-not (Test-Path $repoPath)) {
            DownloadRepoGit -UrlGit $url -Dest $repoPath
        }
        else {
            Write-Host "Repository already exists: ${repoPath}, omitting cloning." -ForegroundColor  $Env:COLOR_SKIP
        }

    }
    catch {
        Write-Error "Error cloning ${entry}: $_"
    }
}

# Phase 2: Install dependencies (npm and NuGet)
Write-Host "=========================> Phase 2: Install dependencies (npm and NuGet)" -ForegroundColor $Env:COLOR_INFO
foreach ($entry in $repoEntries) {
    try {
        $parts = $entry -split '\|'
        $solutionName = $parts[0].Trim() -replace '[^\w\-]', '_'
        $url = $parts[1].Trim()

        $repoFolderName = [System.IO.Path]::GetFileNameWithoutExtension($url) -replace '[^\w\-]', '_'
        $repoPath = Join-Path $WorkDir $repoFolderName

        Write-Host "Checking dependencies in ${repoPath}..." -ForegroundColor $Env:COLOR_INFO

        InstallNpmDependencies -ProjectPath $repoPath
        InstallNugetPackages -ProjectPath $repoPath
    }
    catch {
        Write-Warning "Error installing dependencies in ${entry}: $_"
    }
}

# Phase 3: Execute the scans
Write-Host "=========================> Phase 3: Execute the scans" -ForegroundColor $Env:COLOR_INFO
foreach ($entry in $repoEntries) {
    try {
        $parts = $entry -split '\|'
        $solutionName = $parts[0].Trim() -replace '[^\w\-]', '_'
        $url = $parts[1].Trim()

        $repoFolderName = [System.IO.Path]::GetFileNameWithoutExtension($url) -replace '[^\w\-]', '_'
        $repoPath = Join-Path $WorkDir $repoFolderName
        $reportPath = Join-Path "${WorkDir}" "${solutionName}.csv"

        if (Test-Path $reportPath) {
            Write-Host "Report already exists for '${solutionName}', skipping scan." -ForegroundColor $Env:COLOR_SKIP
            continue
        }

        Write-Host "Scanning solution '${solutionName}' in ${repoPath}..." -ForegroundColor $Env:COLOR_INFO

        RunSecScan -ProjectName $solutionName -ProjectPath $repoPath -WorkDir $WorkDir
    }
    catch {
        Write-Error "Scanning error ${entry}: $_"
    }
}
