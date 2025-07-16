# Powershell
# Major  Minor  Build  Revision
# -----  -----  -----  --------
# 5      1      20348  2849
param (
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [string]$ProjectVersion,

    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$NuGetConfigPath,

    # [Parameter(Mandatory = $true)]
    [string]$DepTrackServer = "https://dt.cyber.chq.ei",

    # [Parameter(Mandatory = $true)]
    [string]$DepTrackApiKey = "odt_JHH2CbBW8FytSidyVBnHCXylc2Its6PE",

    # [Parameter(Mandatory = $true)]
    [string]$MsBuildPath = "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",

    [switch]$VerboseOutput = $false
)

$projectSignatureFiles = @{
    "npm"              = "package.json"
    "dotnet-framework" = "packages.config"
    # "java-maven"     = "pom.xml"
    # "java-gradle"    = "build.gradle"
    # "python"         = "requirements.txt"
}

function Test-ToolAvailability {
    param ([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Assert-RequiredTools {
    if (-not (Test-ToolAvailability "dotnet-cyclonedx")) {
        Write-Error "❌ ERROR: 'dotnet-cyclonedx' is not available on the system."
        exit 1
    }
    if (-not (Test-ToolAvailability "npx")) {
        Write-Error "❌ ERROR: 'npx' is not available. Make sure Node.js is installed."
        exit 1
    }
    if (-not (Test-ToolAvailability "cyclonedx-cli.exe")) {
        Write-Error "❌ ERROR: 'cyclonedx-cli' is not available. Install it to perform merge."
        exit 1
    }
}

function Run-Command {
    param (
        [string]$Command,
        [string[]]$Arguments,
        [switch]$ShowOutput
    )

    if ($ShowOutput) {
        & $Command @Arguments
    }
    else {
        & $Command @Arguments | Out-Null
    }
}

function Find-ProjectsRecursively {
    param ([string]$basePath)

    $projects = @()
    $ignoredFolders = @('bin', 'obj', 'packages', 'node_modules', '.git', '.vs', 'dist', 'build', '.angular')
    $allSignatures = $projectSignatureFiles.Values | Sort-Object -Unique
    $signatureLookup = @{}

    foreach ($key in $projectSignatureFiles.Keys) {
        $sig = $projectSignatureFiles[$key]
        $signatureLookup[$sig] = $key
    }

    Write-Host "`n🔎 Searching for valid project files..." -ForegroundColor Cyan

    Get-ChildItem -Path $basePath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $filename = $_.Name
        $relativePath = $_.FullName.Substring($basePath.Length)
        $isIgnored = $ignoredFolders | Where-Object { $relativePath -match "\\$_(\\|$)" }
        -not $isIgnored -and $filename -in $allSignatures
    } |
    ForEach-Object {
        $filePath = $_.FullName
        $fileName = $_.Name
        $dir = Split-Path $filePath -Parent
        $type = $signatureLookup[$fileName]

        if (-not ($projects | Where-Object { $_.Path -eq $dir })) {
            $projects += [PSCustomObject]@{
                Path = $dir
                Type = $type
            }
        }
    }

    return $projects
}

function Install-Packages {
    param (
        [string]$fullPath,
        [string]$type
    )

    Write-Host "`n==> Processing project: $fullPath" -ForegroundColor Cyan
    Write-Host "   Detected type: $type" -ForegroundColor Cyan

    switch ($type) {
        "npm" {
            if (Test-Path (Join-Path $fullPath 'package.json')) {
                # if (Test-Path (Join-Path $fullPath 'node_modules')) {
                #     Write-Host "   📦 'node_modules' folder detected. Skipping dependency installation." -ForegroundColor Yellow
                # }
                # else {
                Push-Location $fullPath
                try {
                    Write-Host "   📦 Running 'npm ci' to install dependencies..." -ForegroundColor DarkGray
                    Run-Command -Command "npm" -Arguments @("ci") -ShowOutput:$VerboseOutput
                    Write-Host "   ✔ npm ci completed successfully." -ForegroundColor Green
                }
                catch {
                    Write-Error "   ❌ Error during 'npm ci': $_"
                    continue
                }
                finally {
                    Pop-Location
                }
            }
            # }
        }
        "dotnet-framework" {
            # if (Test-Path (Join-Path $fullPath 'packages')) {
            #     Write-Host "   📦 'packages' folder detected. Skipping package restore." -ForegroundColor Yellow
            # }
            # else {
            $packagesConfig = Get-ChildItem -Path $fullPath -Filter "packages.config" -Recurse | Select-Object -First 1
            $csproj = Get-ChildItem -Path $fullPath -Filter "*.csproj" -Recurse | Select-Object -First 1

            if ($packagesConfig -and $csproj) {
                Write-Host "   📦 Restoring NuGet packages with MSBuild..." -ForegroundColor DarkGray
                try {
                    $args = @(
                        "/t:restore",
                        "/p:RestorePackagesConfig=true",
                        "/p:RestoreConfigFile=$NuGetConfigPath",
                        "$($csproj.FullName)"
                    )
                    Run-Command -Command $MsBuildPath -Arguments $args -ShowOutput:$VerboseOutput
                    Write-Host "   ✔ Packages restored successfully." -ForegroundColor Green
                }
                catch {
                    Write-Error "   ❌ Error during NuGet package restore: $_"
                    continue
                }
            }
            else {
                Write-Warning "   ⚠ packages.config or valid .csproj not found in $fullPath"
                continue
            }
            # }
        }
        default {
            Write-Warning "   ⚠ $fullPath is invalid project/type "
        }
    }
}

function Generate-SBOM {
    param (
        [string]$fullPath,
        [string]$type
    )

    $cleanPath = $fullPath.TrimEnd('\')
    $sbomFileName = "sbom.json"
    $sbomFullPath = Join-Path $cleanPath $sbomFileName

    switch ($type) {
        "dotnet-framework" {
            Write-Host "   🛠 Generating SBOM with dotnet-cyclonedx..." -ForegroundColor DarkGray
            Run-Command -Command "dotnet-cyclonedx" -Arguments @($cleanPath, "-j", "-o", $cleanPath, "-fn", $sbomFileName) -ShowOutput:$VerboseOutput
        }
        "npm" {
            Push-Location $cleanPath
            try {
                Write-Host "   🛠 Generating SBOM with npx @cyclonedx/cyclonedx-npm ..." -ForegroundColor DarkGray
                Run-Command -Command "npx" -Arguments @("--yes", "@cyclonedx/cyclonedx-npm", "-o", $sbomFullPath, "--of", "JSON") -ShowOutput:$VerboseOutput
            }
            catch {
                Write-Error "   ❌ Error during SBOM generation: $_"
            }
            finally {
                Pop-Location
            }
        }
        default {
            Write-Warning "   ⚠ Type not yet supported for generation: $type"
            continue
        }
    }

    if (Test-Path $sbomFullPath) {
        $resolvedPath = (Resolve-Path $sbomFullPath).Path
        Write-Host "   ✔ SBOM generated: $resolvedPath" -ForegroundColor Green
        return $resolvedPath
    }
    else {
        Write-Warning "   ❌ sbom.json was not generated in: $cleanPath"
    }
}

function Merge-SBOMs {
    param (
        [string[]]$sbomPaths
    )

    if ($sbomPaths.Count -eq 0) {
        Write-Warning "`n❌ No SBOM files were generated to merge."
        exit 0
    }

    $mergedSbom = Join-Path $currentDir "merged-sbom.json"

    Write-Host "`n📦 Files to merge:" -ForegroundColor Cyan
    $sbomPaths | ForEach-Object { Write-Host " - $_" -ForegroundColor DarkGray }

    $arguments = @(
        "merge",
        "--input-format", "json",
        "--output-format", "json",
        "--output-file", "$mergedSbom",
        "--input-files"
    ) + $sbomPaths

    Run-Command -Command "cyclonedx-cli" -Arguments $arguments -ShowOutput:$VerboseOutput

    Write-Host "`n✅ Merged file generated: $mergedSbom" -ForegroundColor Green

    return $mergedSbom
}

Write-Host "`n============================" -ForegroundColor Cyan
Write-Host "STEP 0: 🧪 Validating installed tools" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

Assert-RequiredTools

$currentDir = Get-Location
$sbomPaths = @()

try {
    $rootFullPath = (Resolve-Path $ProjectPath).Path
}
catch {
    Write-Error "❌ Could not resolve path: $ProjectPath"
    exit 1
}

Write-Host "`n============================" -ForegroundColor Cyan
Write-Host "STEP 1: 🏗 Generating individual SBOMs" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "`n📁 Searching for valid projects in: $rootFullPath ..." -ForegroundColor Cyan
$projectInfos = Find-ProjectsRecursively -basePath $rootFullPath

if ($projectInfos.Count -eq 0) {
    Write-Warning "⚠ No valid projects found in the provided path."
    exit 0
}

foreach ($proj in $projectInfos) {
    Write-Host "✔ Detected project: $($proj.Path) - Type: $($proj.Type)" -ForegroundColor Green
}

Write-Host "`n🏗 Installing packages" -ForegroundColor Cyan
foreach ($proj in $projectInfos) {
    Install-Packages -fullPath $proj.Path -type $proj.Type
    $sbomPaths += Generate-SBOM -fullPath $proj.Path -type $proj.Type
}

Write-Host "`n============================" -ForegroundColor Cyan
Write-Host "STEP 2: 🔄 Merging SBOMs" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$mergedSbom = Merge-SBOMs -sbomPaths $sbomPaths
$mergedSbom = "C:\_audomaro_\repos\edi\EDI_Preclass\webapp\sbom.json"
Write-Host "`n============================" -ForegroundColor Cyan
Write-Host "STEP 3: ☁ Upload to Dependency-Track" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

if (-not (Test-Path $mergedSbom)) {
    Write-Error "❌ The merged file '$mergedSbom' does not exist, cannot upload."
    exit 1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxyUrl)

# PORWERSHELL 7.1
try {

  Write-Host "📤 Uploading SBOM file to Dependency-Track..."

  $headers = @{
    "X-Api-Key" = $DepTrackApiKey
  }

  $formData = @{
    projectName    = $projectName
    projectVersion = $projectVersion
    autoCreate     = "true"
    isLatest       = "true"
    bom            = Get-Item "$mergedSbom"
  }

  $response = Invoke-WebRequest -Uri "$DepTrackServer/api/v1/bom" `
    -Method Post `
    -Headers $headers `
    -Form $formData

  # Parsear la respuesta si es JSON
  $content = $response.Content | ConvertFrom-Json
  Write-Host "`n✅ Upload completed. Token: $($content.token)"
}
catch {
    Write-Error "❌ Error during upload to Dependency-Track: $_"
    if ($_.Exception.InnerException) {
        Write-Error "👉 Inner: $($_.Exception.InnerException.Message)"
    }
}

# CODE FORM POWERSHELL 5.1
try {
    Write-Host "📤 Subiendo archivo SBOM a Dependency-Track..."

    $sbomBytes = [System.IO.File]::ReadAllBytes($mergedSbom)
    $sbomBase64 = [System.Convert]::ToBase64String($sbomBytes)

    $body = @{
        projectName    = $projectName
        projectVersion = $projectVersion
        autoCreate     = $true
        bom            = Get-Item $mergedSbom
    }

    $headers = @{
        "X-Api-Key"    = $DepTrackApiKey
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod `
            -Uri "$DepTrackServer/api/v1/bom" `
            -Method Post `
            -Headers $headers `
            -Form $body

        Write-Host "`n✅ Subida completada. Token: $($response.token)"
    }
    catch {
        Write-Error "Error: $_"
        exit 1
    }
}
catch {
    Write-Error "❌ Error durante la subida a Dependency-Track: $_"
    if ($_.Exception.InnerException) {
        Write-Error "👉 Inner: $($_.Exception.InnerException.Message)"
    }
}