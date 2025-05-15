param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ProjectName.")]
  [ValidateNotNullOrEmpty()]
  [string]$ProjectName,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ProjectPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ProjectPath
)

try {
  if (-not (Test-Path "reports")) {
    New-Item -Path "reports" -ItemType Directory
  }

  # Construir las rutas completas utilizando las variables del entorno y los parámetros
  $ReportPath = Join-Path -Path $env:CI_PROJECT_DIR -ChildPath "reports/"

  # Verificar si la ruta del proyecto existe
  if (-not (Test-Path -Path $ProjectPath)) {
    Write-Host "La ruta del proyecto no existe: $ProjectPath"
    exit 1
  }

  # Ejecutar la herramienta dependency-check con los parámetros adecuados
  Write-Host "Ejecutando Dependency Check para el proyecto: $ProjectName"
  & "dependency-check.bat" --project "$ProjectName" -s "$ProjectPath" --disableOssIndex --exclude "**/node_modules/**,**/packages/**" -n `
    -o "$ReportPath/" `
    --format CSV `
    --format GITLAB `
    --format HTML 

  # Renombrar archivos generados en la carpeta reports con el nombre del proyecto
  $filesToRename = @{
    "dependency-check-report.csv"   = "$ProjectName.csv"
    "dependency-check-report.html"  = "$ProjectName.html"
    "dependency-check-gitlab.json"  = "$ProjectName.json"
  }

  foreach ($originalName in $filesToRename.Keys) {
    $originalFile = Join-Path -Path $ReportPath -ChildPath $originalName
    $newFile = Join-Path -Path $ReportPath -ChildPath $filesToRename[$originalName]

    if (Test-Path $originalFile) {
      Rename-Item -Path $originalFile -NewName $newFile
      Write-Host "Archivo renombrado: $newFile"
    } else {
      Write-Host "No se encontró el archivo: $originalFile"
    }
  }

  Write-Host "Análisis completado. Los reportes están disponibles en: $ReportPath"
  exit 0
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
