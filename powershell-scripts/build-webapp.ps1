param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ProjectPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ProjectPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para EnvironmentBuild.")]
  [ValidateNotNullOrEmpty()]
  [string]$EnvironmentBuild,
  [bool]$Legacy = $false
)

try {
  $EnvironmentBuild = $EnvironmentBuild.ToLower()

  # Instalamos dependencias y realizamos la compilación de producción
  Write-Host "Instalando dependencias para el proyecto..."

  # Cambiar el directorio al proyecto web
  Push-Location $ProjectPath

  $npmCommand = 'npm install'

  if ($Legacy) {
    $npmCommand += ' --legacy-peer-deps'
  }

  # Instalar dependencias
  Write-Host "Ejecutando '$npmCommand'..."
  Invoke-Expression $npmCommand

  # Realizar la compilación en modo producción
  Write-Host "Ejecutando 'npm run build:$EnvironmentBuild'..."
  npm run build:$EnvironmentBuild

  # Volver al directorio original
  Pop-Location

  # Verificamos si hubo un error en los comandos anteriores
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Ocurrió un error durante la instalación o compilación."
    exit $LASTEXITCODE
  }

  Write-Host "Dependencias instaladas y proyecto compilado correctamente."

}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
