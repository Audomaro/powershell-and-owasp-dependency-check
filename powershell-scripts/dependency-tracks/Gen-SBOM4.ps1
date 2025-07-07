param (
    [Parameter(Mandatory = $true)]
    [string]$ApplicationPath
)

if (-not (Test-Path $ApplicationPath)) {
    Write-Error "❌ La ruta especificada no existe: $ApplicationPath"
    exit 1
}

if (-not (Get-Command "syft" -ErrorAction SilentlyContinue)) {
    Write-Error "⚠️ Syft no está instalado o no está en el PATH."
    exit 1
}

if (-not (Get-Command "cyclonedx" -ErrorAction SilentlyContinue)) {
    Write-Error "⚠️ CycloneDX CLI no está instalado o no está en el PATH."
    exit 1
}

$ResolvedPath = Resolve-Path $ApplicationPath
$TempDepsDir = Join-Path $env:TEMP "deps_json_temp"
$TempSBOMDir = Join-Path $env:TEMP "sbom_temp"
$FinalSBOM = Join-Path $ResolvedPath "sbom_merged.json"

# Crear carpetas temporales limpias
foreach ($dir in @($TempDepsDir, $TempSBOMDir)) {
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
    New-Item -ItemType Directory -Path $dir | Out-Null
}

Write-Host "📦 Generando SBOM para: $ResolvedPath"

$ExcludePatterns = @(
    "**/*.ts", "**/*.html", "**/*.scss", "**/*.md", "**/*.log",
    "**/*.cs", "**/*.vb", "**/*.designer.cs", "**/*.resx",
    "**/bin/**", "**/obj/**", "**/.vs/**", "**/dist/**", "**/coverage/**",
    "**/TestResults/**", "**/Debug/**", "**/Release/**",
    "**/node_modules/**", "**/packages/**", "**/.angular/**"
)

# Procesar packages.config
$PackagesConfigFiles = Get-ChildItem -Path $ResolvedPath -Recurse -Filter "packages.config" -ErrorAction SilentlyContinue

if ($PackagesConfigFiles.Count -gt 0) {
    Write-Host "📄 Detectados $($PackagesConfigFiles.Count) packages.config, creando archivos deps.json temporales..."

    foreach ($pkgConfig in $PackagesConfigFiles) {
        try {
            [xml]$xml = Get-Content $pkgConfig.FullName
            $depsJson = @{
                runtimeTarget = @{
                    name = ""
                    dependencies = @{}
                }
            }
            foreach ($pkg in $xml.packages.package) {
                $depsJson.runtimeTarget.dependencies[$pkg.id] = @{ version = $pkg.version }
            }

            $jsonPath = Join-Path $TempDepsDir ("deps_" + ($pkgConfig.DirectoryName -replace '[\\:]', '_') + ".deps.json")
            $depsJson | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $jsonPath
        }
        catch {
            Write-Warning "⚠️ Error procesando $($pkgConfig.FullName): $_"
        }
    }
} else {
    Write-Host "ℹ️ No se encontraron archivos packages.config."
}

# Construir argumentos exclusión
$ExcludeArgs = @()
foreach ($pattern in $ExcludePatterns) {
    $ExcludeArgs += "--exclude"
    $ExcludeArgs += $pattern
}

# Generar SBOM principal
$MainSBOM = Join-Path $TempSBOMDir "main_sbom.json"
Write-Host "🧪 Generando SBOM para código principal..."
Push-Location $ResolvedPath
try {
    & syft "dir:." --output cyclonedx-json @ExcludeArgs > $MainSBOM
} catch {
    Pop-Location
    Write-Error "❌ Error generando SBOM principal: $_"
    exit 1
}
Pop-Location

# Generar SBOM para deps.json si existen
$DepSBOMs = @()
if ((Get-ChildItem $TempDepsDir -Filter *.deps.json -ErrorAction SilentlyContinue).Count -gt 0) {
    Write-Host "🧪 Generando SBOM para archivos deps.json temporales..."

    foreach ($file in Get-ChildItem $TempDepsDir -Filter *.deps.json) {
        $outFile = Join-Path $TempSBOMDir ("sbom_" + $file.BaseName + ".json")
        Push-Location $file.DirectoryName
        try {
            & syft "file:$($file.FullName)" --output cyclonedx-json > $outFile
            $DepSBOMs += $outFile
        } catch {
            Write-Warning "⚠️ Error generando SBOM para $($file.FullName): $_"
        }
        Pop-Location
    }
}

# Combinar SBOMs
Write-Host "`n🔗 Combinando SBOMs..."
$MergeArgs = @("--output-file", $FinalSBOM, "--input-files", $MainSBOM)
foreach ($depSbom in $DepSBOMs) {
    $MergeArgs += "--input-files"
    $MergeArgs += $depSbom
}

try {
    & cyclonedx merge @MergeArgs
    Write-Host "✅ SBOM combinado generado en: $FinalSBOM"
}
catch {
    Write-Error "❌ Error combinando SBOMs: $_"
    exit 1
}

# Limpiar
Remove-Item $TempDepsDir, $TempSBOMDir -Recurse -Force

