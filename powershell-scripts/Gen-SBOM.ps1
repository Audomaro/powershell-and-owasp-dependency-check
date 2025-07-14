param (
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$NuGetConfigPath,

    [string]$MsBuildPath = "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
)

# === 🔍 Lista interna de tipos de proyecto y su archivo característico ===
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
        Write-Error "ERROR: 'dotnet-cyclonedx' no está disponible en el sistema."
        exit 1
    }
    if (-not (Test-ToolAvailability "npx")) {
        Write-Error "ERROR: 'npx' no está disponible. Asegúrate de tener Node.js instalado."
        exit 1
    }
    if (-not (Test-ToolAvailability "cyclonedx-cli")) {
        Write-Error "ERROR: 'cyclonedx-cli' no está disponible. Instálalo para hacer merge."
        exit 1
    }
}

function Find-ProjectsRecursively {
    param (
        [string]$basePath
    )

    $projects = @()
    $ignoredFolders = @('bin', 'obj', 'packages', 'node_modules', '.git', '.vs', 'dist', 'build', '.angular')
    $allSignatures = $projectSignatureFiles.Values | Sort-Object -Unique
    $signatureLookup = @{}

    foreach ($key in $projectSignatureFiles.Keys) {
        $sig = $projectSignatureFiles[$key]
        $signatureLookup[$sig] = $key
    }

    Write-Host "`n🔎 Buscando archivos de proyecto válidos..."

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

# === PASO 0: Validación de herramientas ===
Write-Host "`n============================"
Write-Host "PASO 0: 🧪 Validando herramientas instaladas"
Write-Host "============================"
Assert-RequiredTools

$currentDir = Get-Location
$sbomPaths = @()

try {
    $rootFullPath = (Resolve-Path $ProjectPath).Path
}
catch {
    Write-Error "❌ No se pudo resolver la ruta: $ProjectPath"
    exit 1
}

Write-Host "`n============================"
Write-Host "PASO 1: 🏗 Generación de SBOMs individuales"
Write-Host "============================"
Write-Host "`n📁 Buscando proyectos válidos en: $rootFullPath ..."
$projectInfos = Find-ProjectsRecursively -basePath $rootFullPath

if ($projectInfos.Count -eq 0) {
    Write-Warning "⚠ No se encontraron proyectos válidos en la ruta proporcionada."
    exit 0
}

foreach ($proj in $projectInfos) {
    Write-Host "Proyecto detectado: $($proj.Path) - Tipo: $($proj.Type)"
}

Write-Host " 🏗 Instalación de paquetes"
foreach ($proj in $projectInfos) {
    $fullPath = $proj.Path
    $type = $proj.Type

    Write-Host "`n==> Procesando proyecto: $fullPath"
    Write-Host "   Tipo detectado: $type"

    # === INSTALACIÓN DE DEPENDENCIAS SEGÚN TIPO ===
    switch ($type) {
        "npm" {
            if (Test-Path (Join-Path $fullPath 'package.json')) {
                Push-Location $fullPath
                try {
                    Write-Host "   📦 Ejecutando 'npm ci --silent' para instalar dependencias..." -ForegroundColor DarkGray
                    npm ci --silent
                    Write-Host "   ✔ npm ci completado exitosamente." -ForegroundColor Green
                } catch {
                    Write-Error "   ❌ Error durante 'npm ci': $_"
                    continue
                } finally {
                    Pop-Location
                }
            }
        }
        "dotnet-framework" {
            $packagesConfig = Get-ChildItem -Path $fullPath -Filter "packages.config" -Recurse | Select-Object -First 1
            $csproj = Get-ChildItem -Path $fullPath -Filter "*.csproj" -Recurse | Select-Object -First 1

            if ($packagesConfig -and $csproj) {
                Write-Host "   📦 Restaurando paquetes NuGet con MSBuild..." -ForegroundColor DarkGray
                try {
                    & "$MsBuildPath" "/t:restore" `
                        "/p:RestorePackagesConfig=true" `
                        "/p:RestoreConfigFile=$NuGetConfigPath" `
                        "$($csproj.FullName)"
                    Write-Host "   ✔ Paquetes restaurados exitosamente." -ForegroundColor Green
                } catch {
                    Write-Error "   ❌ Error durante la restauración de paquetes NuGet: $_"
                    continue
                }
            } else {
                Write-Warning "   ⚠ No se encontró packages.config o .csproj válido en $fullPath"
                continue
            }
        }
    }

    # === GENERACIÓN DE SBOM ===
    $cleanPath = $fullPath.TrimEnd('\')
    $sbomFileName = "sbom.json"
    $sbomFullPath = Join-Path $cleanPath $sbomFileName

    switch ($type) {
        "dotnet-framework" {
            Write-Host "   🛠 Generando SBOM con dotnet-cyclonedx..."
            & dotnet-cyclonedx $cleanPath -j -o $cleanPath -fn $sbomFileName
        }
        "npm" {
            Push-Location $cleanPath
            try {
                Write-Host "   🛠 Generando SBOM con npx @cyclonedx/cyclonedx-npm ..."
                npx --yes @cyclonedx/cyclonedx-npm -o $sbomFullPath --of JSON
            }
            finally {
                Pop-Location
            }
        }
        default {
            Write-Warning "   ⚠ Tipo no soportado aún para generación: $type"
            continue
        }
    }

    if (Test-Path $sbomFullPath) {
        $resolvedPath = (Resolve-Path $sbomFullPath).Path
        $sbomPaths += $resolvedPath
        Write-Host "   ✔ SBOM generado: $resolvedPath"
    }
    else {
        Write-Warning "   ❌ No se generó sbom.json en: $cleanPath"
    }
}

foreach ($proj in $projectInfos) {
    $fullPath = $proj.Path
    $type = $proj.Type

    Write-Host "`n==> Procesando proyecto: $fullPath"
    Write-Host "   Tipo detectado: $type"

    $cleanPath = $fullPath.TrimEnd('\')
    $sbomFileName = "sbom.json"
    $sbomFullPath = Join-Path $cleanPath $sbomFileName

    switch ($type) {
        "dotnet-framework" {
            Write-Host "   🛠 Generando SBOM con dotnet-cyclonedx..."
            & dotnet-cyclonedx $cleanPath -j -o $cleanPath -fn $sbomFileName
        }
        "npm" {
            Push-Location $cleanPath
            try {
                Write-Host "   🛠 Generando SBOM con npx @cyclonedx/cyclonedx-npm ..."
                npx --yes @cyclonedx/cyclonedx-npm -o $sbomFullPath --of JSON
            }
            finally {
                Pop-Location
            }
        }
        default {
            Write-Warning "   ⚠ Tipo no soportado aún para generación: $type"
            continue
        }
    }

    if (Test-Path $sbomFullPath) {
        $resolvedPath = (Resolve-Path $sbomFullPath).Path
        $sbomPaths += $resolvedPath
        Write-Host "   ✔ SBOM generado: $resolvedPath"
    }
    else {
        Write-Warning "   ❌ No se generó sbom.json en: $cleanPath"
    }
}

# === PASO 2: 🔄 Merge de SBOMs ===
Write-Host "`n============================"
Write-Host "PASO 2: 🔄 Merge de SBOMs"
Write-Host "============================"

if ($sbomPaths.Count -eq 0) {
    Write-Warning "`n❌ No se generaron archivos SBOM para hacer merge."
    exit 0
}

$mergedSbom = Join-Path $currentDir "merged-sbom.json"

Write-Host "`n📦 Archivos a mergear:"
$sbomPaths | ForEach-Object { Write-Host " - $_" }

# Preparar argumentos para merge
$arguments = @(
    "merge",
    "--input-format", "json",
    "--output-format", "json",
    "--output-file", "$mergedSbom",
    "--input-files"
) + $sbomPaths

# Ejecutar merge
& cyclonedx-cli @arguments

Write-Host "`n✅ Archivo mergeado generado: $mergedSbom"

# === PASO 3: ☁ Subida a Dependency-Track ===
Write-Host "`n============================"
Write-Host "PASO 3: ☁ Subida a Dependency-Track"
Write-Host "============================"

# ⚠️ CONFIGURA ESTOS VALORES:
$dependencyTrackApiKey = "odt_JHH2CbBW8FytSidyVBnHCXylc2Its6PE"
$dependencyTrackBaseUrl = "https://dt.cyber.chq.ei"

# Puedes ajustar nombre/versión si quieres identificar builds distintos
$projectName = "MEXICO APPS/Portal EDI HP"
$projectVersion = "1.0.0"
$proxyUrl = "http://proxy.chq.ei:8080"

if (-not (Test-Path $mergedSbom)) {
    Write-Error "❌ El archivo mergeado '$mergedSbom' no existe, no se puede subir."
    exit 1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    Write-Host "📤 Subiendo archivo SBOM a Dependency-Track..."

    $headers = @{
        "X-Api-Key" = $dependencyTrackApiKey
    }

    $formData = @{
        projectName    = $projectName
        projectVersion = $projectVersion
        autoCreate     = "true"
        isLatest       = "true"
        bom            = Get-Item "$mergedSbom"
    }

    $response = Invoke-RestMethod -Uri "$dependencyTrackBaseUrl/api/v1/bom" `
        -Method Post `
        -Headers $headers `
        -Form $formData

    Write-Host "`n✅ Subida completada. Token: $($response.token)"
}
catch {
    Write-Error "❌ Error durante la subida a Dependency-Track: $_"
    if ($_.Exception.InnerException) {
        Write-Error "👉 Inner: $($_.Exception.InnerException.Message)"
    }
}