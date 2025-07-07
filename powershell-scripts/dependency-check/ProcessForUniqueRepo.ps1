param(
    [Parameter(Mandatory = $false)]
    [string]$WorkDir,

    [Parameter(Mandatory = $true)]
    [string]$SolutionName
)

# Load functions from an external script located in the "scripts" folder
. "${PSScriptRoot}\scripts\Config.ps1"
. "${PSScriptRoot}\scripts\DownloadRepoGit.ps1"
. "${PSScriptRoot}\scripts\RunSecScan.ps1"
. "${PSScriptRoot}\scripts\InstallNpmDependencies.ps1"
. "${PSScriptRoot}\scripts\InstallNugetPackages.ps1"
. "${PSScriptRoot}\scripts\GenerateCvss3Summary.ps1"

# Phase 1: Install dependencies (npm and NuGet)
try {
    Write-Host "Checking dependencies in ${WorkDir}..." -ForegroundColor $Env:COLOR_INFO

    InstallNpmDependencies -ProjectPath $WorkDir
    InstallNugetPackages -ProjectPath $WorkDir
}
catch {
    Write-Warning "Error installing dependencies in ${entry}: $_"
}

# Phase 2: Execute the scans
Write-Host "=========================> Phase 3: Execute the scans" -ForegroundColor $Env:COLOR_INFO
try {
    $reportPath = Join-Path "${WorkDir}" "${SolutionName}.csv"

    if (Test-Path $reportPath) {
        Write-Host "Report already exists for '${SolutionName}', skipping scan." -ForegroundColor $Env:COLOR_SKIP
        continue
    }

    Write-Host "Scanning solution '${SolutionName}' in ${WorkDir}..." -ForegroundColor $Env:COLOR_INFO

    RunSecScan -ProjectName $SolutionName -ProjectPath $WorkDir -WorkDir $WorkDir
}
catch {
    Write-Error "Scanning error ${entry}: $_"
}

# Phase 3: Custom summary, get all CSV files inside the repo folder
$csvFiles = Get-ChildItem -Path $WorkDir -Filter *.csv -ErrorAction SilentlyContinue

# Loop through each CSV and generate the summary
foreach ($csv in $csvFiles) {
    Write-Host "Processing: $($csv.FullName)" -ForegroundColor $Env:COLOR_INFO
    GenerateCvss3Summary -CsvPath $csv.FullName
}