Param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ProjectPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ProjectPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para MsbuildPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$MsbuildPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para NugetConfigPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$NugetConfigPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para EnvironmentBuild.")]
  [ValidateNotNullOrEmpty()]
  [string]$EnvironmentBuild
)

try {
  # Validación de la ruta de MSBuild
  if (-not (Test-Path -Path $MsbuildPath)) {
    Write-Host "Error: No se encontró MSBuild en la ruta especificada: $MsbuildPath"
    exit 1
  }

  # Validación del archivo de configuración de NuGet
  if (-not (Test-Path -Path $NugetConfigPath)) {
    Write-Host "Error: No se encontró el archivo de configuración de NuGet en: $NugetConfigPath"
    exit 1
  }

  # Validación del proyecto de API
  if (-not (Test-Path -Path $ProjectPath)) {
    Write-Host "Error: No se encontró el proyecto en la ruta especificada: $ProjectPath"
    exit 1
  }

  # Restaurar paquetes de NuGet
  Write-Host "Restaurando paquetes de NuGet para el proyecto: $ProjectPath..."
  & $MsbuildPath /t:restore /p:RestorePackagesConfig=true /p:RestoreConfigFile=$NugetConfigPath $ProjectPath

  # Compilar el proyecto en configuración de producción
  Write-Host "Compilando el proyecto: $ProjectPath en modo de $EnvironmentBuild..."
  & $MsbuildPath $ProjectPath /p:Configuration=$EnvironmentBuild /clp:ErrorsOnly

  # Verificación de errores en la compilación
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: La compilación del proyecto falló."
    exit $LASTEXITCODE
  }

  Write-Host "El proyecto se compiló correctamente."
  exit 0
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
