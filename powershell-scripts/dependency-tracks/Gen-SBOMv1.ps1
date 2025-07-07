# function Gen-SBOM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    if (-not (Test-Path $RootPath)) {
        Write-Error "❌ El path especificado no existe: $RootPath"
        return
    }

    if (-not (Get-Command "syft" -ErrorAction SilentlyContinue)) {
        Write-Error "⚠️ Syft no está instalado o no está en PATH."
        return
    }

    if (-not (Get-Command "cyclonedx" -ErrorAction SilentlyContinue)) {
        Write-Error "⚠️ CycloneDX CLI no está instalado o no está en PATH."
        return
    }

    $ResolvedRoot = Resolve-Path $RootPath
    $TempSBOMDir = Join-Path $ResolvedRoot "sbom_temp"
    $FinalSBOM = Join-Path $ResolvedRoot "merged-sbom.json"

    if (-not (Test-Path $TempSBOMDir)) {
        New-Item -ItemType Directory -Path $TempSBOMDir | Out-Null
    }

    Write-Host "📦 Iniciando generación de SBOMs por proyecto..."

    # Patrones que Syft ignorará
    $ExcludePatterns = @(
        "**/*.ts", "**/*.html", "**/*.scss", "**/*.md", "**/*.log",
        "**/*.cs", "**/*.vb", "**/*.designer.cs", "**/*.resx",
        "**/bin/**", "**/obj/**", "**/.vs/**", "**/dist/**", "**/coverage/**",
        "**/TestResults/**", "**/Debug/**", "**/Release/**", "**/node_modules/**", "**/.angular/**"
    )

    # Carpetas a ignorar en la búsqueda
    $FolderIgnoreList = @("node_modules", "bin", "obj", ".vs", "dist", "coverage", "TestResults", "Debug", "Release")

    # Detectar proyectos relevantes
    $Projects = Get-ChildItem -Recurse -Directory -Path $ResolvedRoot | Where-Object {
        $dirName = $_.Name.ToLower()
        -not ($FolderIgnoreList -contains $dirName) -and (
            (Test-Path (Join-Path $_.FullName "package.json")) -or
            (Test-Path (Join-Path $_.FullName "packages.config")) -or
            (Get-ChildItem $_.FullName -Filter *.csproj -ErrorAction SilentlyContinue)
        ) -and
        ($_.FullName -notmatch "\\node_modules\\")
    }

    $TempFiles = @()
    $Counter = 0

    foreach ($Proj in $Projects) {
        Push-Location $Proj.FullName

        $SafeName = ($Proj.FullName -replace [regex]::Escape($ResolvedRoot), "") -replace "[\\/:*?""<>|]", "_" -replace "^_+", ""
        $OutputFile = Join-Path $TempSBOMDir "sbom_$SafeName.json"

        $SyftArgs = @("dir:.", "--output", "cyclonedx-json")
        foreach ($pattern in $ExcludePatterns) {
            $SyftArgs += "--exclude"
            $SyftArgs += $pattern
        }

        Write-Host "🧪 Generando SBOM para: $($Proj.FullName)"
        $sbomContent = & syft @SyftArgs
        [System.IO.File]::WriteAllText($OutputFile, $sbomContent, [System.Text.Encoding]::UTF8)

        $TempFiles += $OutputFile
        Pop-Location
        $Counter++
    }

    if ($TempFiles.Count -gt 0) {
        Write-Host "`n🔗 Combinando $($TempFiles.Count) SBOM(s) en: $FinalSBOM ..."

        $mergeArgs = @()
        foreach ($file in $TempFiles) {
            $mergeArgs += "--input-files"
            $mergeArgs += $file
        }

        $mergeArgs += "--output-file"
        $mergeArgs += $FinalSBOM

        & cyclonedx merge @mergeArgs

        Write-Host "✅ SBOM combinado creado correctamente: $FinalSBOM"

        # Limpieza robusta
        Write-Host "🧹 Eliminando archivos temporales..."
        try {
            Get-ChildItem -Path $TempSBOMDir -Recurse -File | ForEach-Object {
                try {
                    Remove-Item $_.FullName -Force -ErrorAction Stop
                } catch {
                    Write-Warning "⚠️ No se pudo eliminar: $($_.FullName)"
                }
            }
            Remove-Item $TempSBOMDir -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "🧹 Archivos temporales eliminados correctamente."
        } catch {
            Write-Warning "⚠️ No se pudo eliminar el directorio temporal. Puede estar en uso."
        }
    } else {
        Write-Warning "⚠️ No se generaron SBOMs individuales. Nada que combinar."
    }
# }
