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

    # Carpetas a ignorar (exactos)
    $FolderIgnoreList = @("node_modules", "packages", "bin", "obj", ".vs", "dist", "coverage", "TestResults", "Debug", "Release")

    function IsPathIgnored {
        param([string]$path)
        return $FolderIgnoreList | ForEach-Object { $path -like "*\$_\*" } | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
    }

    # Buscar archivos de manifiesto NPM
    $NpmManifests = Get-ChildItem -Path $ResolvedRoot -Recurse -Include "package.json" -File -ErrorAction SilentlyContinue |
        Where-Object { -not (IsPathIgnored $_.FullName) }

    # Buscar archivos de manifiesto NuGet
    $NugetManifests = Get-ChildItem -Path $ResolvedRoot -Recurse -Include "packages.config" -File -ErrorAction SilentlyContinue |
        Where-Object { -not (IsPathIgnored $_.FullName) }

    $AllManifests = $NpmManifests + $NugetManifests

    Write-Host $AllManifests

    # if ($AllManifests.Count -eq 0) {
    #     Write-Warning "⚠️ No se encontraron archivos de manifiesto para generar SBOM."
    #     exit 0
    # }

    # $TempFiles = @()

    # foreach ($manifest in $AllManifests) {
    #     $projectDir = Split-Path $manifest.FullName -Parent
    #     $SafeName = ($projectDir -replace [regex]::Escape($ResolvedRoot), "") -replace "[\\/:*?""<>|]", "_" -replace "^_+", ""
    #     $OutputFile = Join-Path $TempSBOMDir "sbom_$SafeName.json"

    #     Write-Host "🧪 Generando SBOM para: $($manifest.FullName)"

    #     # Generar SBOM solo desde el archivo manifiesto (no desde la carpeta completa)
    #     $sbomContent = & syft "file:$($manifest.FullName)" --output cyclonedx-json

    #     [System.IO.File]::WriteAllText($OutputFile, $sbomContent, [System.Text.Encoding]::UTF8)

    #     $TempFiles += $OutputFile
    # }

    # Write-Host "`n🔗 Combinando $($TempFiles.Count) SBOM(s) en: $FinalSBOM ..."

    # $mergeArgs = @()
    # foreach ($file in $TempFiles) {
    #     $mergeArgs += "--input-files"
    #     $mergeArgs += $file
    # }
    # $mergeArgs += "--output-file"
    # $mergeArgs += $FinalSBOM

    # & cyclonedx merge @mergeArgs

    # Write-Host "✅ SBOM combinado creado correctamente: $FinalSBOM"

    # Write-Host "🧹 Eliminando archivos temporales..."
    # try {
    #     Remove-Item $TempSBOMDir -Recurse -Force -ErrorAction Stop
    #     Write-Host "🧹 Archivos temporales eliminados correctamente."
    # } catch {
    #     Write-Warning "⚠️ No se pudo eliminar el directorio temporal. Puede estar en uso."
    # }
}