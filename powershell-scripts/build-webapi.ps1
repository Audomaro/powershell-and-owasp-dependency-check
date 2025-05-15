param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ProjectPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ProjectPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para MsBuildPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$MsBuildPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para NuGetConfigPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$NuGetConfigPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para EnvironmentBuild.")]
  [ValidateNotNullOrEmpty()]
  [string]$EnvironmentBuild
)

try {
  # Verificar que las rutas proporcionadas existan
  if (-not (Test-Path -Path $MsBuildPath)) {
    Write-Host "Error: No se encontró la ruta de MSBuild: $MsBuildPath"
    exit 1
  }

  if (-not (Test-Path -Path $NuGetConfigPath)) {
    Write-Host "Error: No se encontró el archivo de configuración de NuGet: $NuGetConfigPath"
    exit 1
  }

  if (-not (Test-Path -Path $ProjectPath)) {
    Write-Host "Error: No se encontró el proyecto en la ruta: $ProjectPath"
    exit 1
  }

  # Restaurar los paquetes NuGet antes de la compilación
  Write-Host "Restaurando paquetes NuGet..."
  & $MsBuildPath /t:restore /p:RestorePackagesConfig=true /p:RestoreConfigFile=$NuGetConfigPath $ProjectPath

  # Verificamos si hubo un error durante la restauración de paquetes
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Ocurrió un error durante la restauración de paquetes NuGet."
    exit $LASTEXITCODE
  }

  # Compilar el proyecto y publicarlo
  Write-Host "Compilando y publicando el proyecto en el entorno: $EnvironmentBuild..."
  & $MsBuildPath $ProjectPath /p:DeployOnBuild=true /p:Configuration=$EnvironmentBuild /clp:ErrorsOnly /P:PublishProfile="$EnvironmentBuild.pubxml"

  # Verificamos si hubo un error en el proceso de compilación
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Ocurrió un error durante la compilación y publicación del proyecto."
    exit $LASTEXITCODE
  }

  Write-Host "Proyecto compilado y publicado correctamente en el entorno $EnvironmentBuild."
  exit 0
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
