#v3
function Gen-SBOM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    if (-not (Test-Path $RootPath)) {
        Write-Error "❌ El path especificado no existe: $RootPath"
        exit 1
    }

    if (-not (Get-Command "syft" -ErrorAction SilentlyContinue)) {
        Write-Error "⚠️ Syft no está instalado o no está en PATH."
        exit 1
    }

    if (-not (Get-Command "cyclonedx" -ErrorAction SilentlyContinue)) {
        Write-Error "⚠️ CycloneDX CLI no está instalado o no está en PATH."
        exit 1
    }

    $ResolvedRoot = Resolve-Path $RootPath
    $TempSBOMDir = Join-Path $ResolvedRoot "sbom_temp"
    $FinalSBOM = Join-Path $ResolvedRoot "merged-sbom.json"

    if (-not (Test-Path $TempSBOMDir)) {
        New-Item -ItemType Directory -Path $TempSBOMDir | Out-Null
    }

    Write-Host "📦 Iniciando generación de SBOMs desde manifiestos..."

    $IgnoredFolders = @{
        "node_modules" = $true; "packages" = $true
        "bin" = $true; "obj" = $true; ".vs" = $true
        "dist" = $true; "coverage" = $true
        "TestResults" = $true; "Debug" = $true; "Release" = $true
    }

    function IsPathIgnored($fullPath) {
        foreach ($folder in $IgnoredFolders.Keys) {
            if ($fullPath -match "\\$folder(\\|$)") {
                return $true
            }
        }
        return $false
    }

    # Buscar manifiestos (mejorado con múltiples búsquedas paralelas)
    $manifestFiles = @()
    $manifestFiles += Get-ChildItem -Path $ResolvedRoot -Recurse -File -Filter "package.json" -ErrorAction SilentlyContinue
    $manifestFiles += Get-ChildItem -Path $ResolvedRoot -Recurse -File -Filter "packages.config" -ErrorAction SilentlyContinue
    $manifestFiles = $manifestFiles | Where-Object { -not (IsPathIgnored $_.FullName) }

    if (-not $manifestFiles -or $manifestFiles.Count -eq 0) {
        Write-Warning "⚠️ No se encontraron archivos de manifiesto para generar SBOM."
        exit 0
    }

    $TempFiles = @()

    foreach ($manifest in $manifestFiles) {
        $projectDir = Split-Path $manifest.FullName -Parent
        $SafeName = ($projectDir -replace [regex]::Escape($ResolvedRoot), "") -replace "[\\/:*?""<>|]", "_" -replace "^_+", ""
        $OutputFile = Join-Path $TempSBOMDir "sbom_$SafeName.json"

        Write-Host "🧪 Generando SBOM para: $($manifest.FullName)"

        try {
            $sbomContent = & syft "file:$($manifest.FullName)" --output cyclonedx-json
            if ($sbomContent) {
                [System.IO.File]::WriteAllText($OutputFile, $sbomContent, [System.Text.Encoding]::UTF8)
                $TempFiles += $OutputFile
            } else {
                Write-Warning "⚠️ SBOM vacío o fallido para: $($manifest.FullName)"
            }
        } catch {
            Write-Warning "❌ Error generando SBOM para: $($manifest.FullName)"
        }
    }

    if ($TempFiles.Count -eq 0) {
        Write-Warning "⚠️ No se generaron SBOMs válidos. Nada que combinar."
        exit 0
    }

    Write-Host "`n🔗 Combinando $($TempFiles.Count) SBOM(s) en: $FinalSBOM ..."

    $mergeArgs = @("--output-file", $FinalSBOM)
    foreach ($file in $TempFiles) {
        $mergeArgs += "--input-files"
        $mergeArgs += $file
    }

    & cyclonedx merge @mergeArgs

    Write-Host "✅ SBOM combinado creado correctamente: $FinalSBOM"

    Write-Host "🧹 Eliminando archivos temporales..."
    try {
        Remove-Item $TempSBOMDir -Recurse -Force -ErrorAction Stop
        Write-Host "🧹 Archivos temporales eliminados correctamente."
    } catch {
        Write-Warning "⚠️ No se pudo eliminar el directorio temporal. Puede estar en uso."
    }
}
