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
  [string]$ReleasePath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para EnvironmentBuild.")]
  [ValidateNotNullOrEmpty()]
  [string]$EnvironmentBuild,
  [Parameter(Mandatory = $false, HelpMessage = "Por favor ingrese el valor para ExcludeDirectories.")]
  [string[]]$ExcludeDirectories
)

try {
  # Verificar que las rutas proporcionadas existan
  if (-not (Test-Path -Path $MsBuildPath)) {
    Write-Host "Error: No se encontrÃƒÂ³ la ruta de MSBuild: $MsBuildPath"
    exit 1
  }

  if (-not (Test-Path -Path $NuGetConfigPath)) {
    Write-Host "Error: No se encontrÃ³ el archivo de configuraciÃ³n de NuGet: $NuGetConfigPath"
    exit 1
  }

  if (-not (Test-Path -Path $ProjectPath)) {
    Write-Host "Error: No se encontrÃƒÂ³ el proyecto en la ruta: $ProjectPath"
    exit 1
  }

  # Restaurar los paquetes NuGet antes de la compilaciÃ³n
  Write-Host "Restaurando paquetes NuGet..."
  & $MsBuildPath /t:restore /p:RestorePackagesConfig=true /p:RestoreConfigFile=$NuGetConfigPath $ProjectPath

  # Verificamos si hubo un error durante la restauraciÃ³n de paquetes
  if ($LASTEXITCODE -ne 0) {
    Write-Host "OcurriÃ³ un error durante la restauraciÃ³n de paquetes NuGet."
    exit $LASTEXITCODE
  }

  Write-Host "Compilando y publicando el proyecto en el entorno: $EnvironmentBuild..."
  & $MsBuildPath $ProjectPath /p:DeployOnBuild=true /p:Configuration=$EnvironmentBuild /t:TransformWebConfig /p:OutputPath=$ReleasePath

  # Verificamos si hubo un error en el proceso de compilaciÃƒÂ³n
  if ($LASTEXITCODE -ne 0) {
    Write-Host "OcurriÃƒÂ³ un error durante la compilaciÃƒÂ³n y publicaciÃƒÂ³n del webconfig del proyecto."
    exit $LASTEXITCODE
  }

  Write-Host "Web.config transformado correctamente en el entorno $EnvironmentBuild."
  exit 0
}
catch {
  Write-Host "OcurriÃƒÂ³ un error: $($_.Exception.Message)"
  exit 1
}
