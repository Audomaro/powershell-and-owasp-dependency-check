param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para InstallUtilPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$InstallUtilPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ServiceName.")]
  [ValidateNotNullOrEmpty()]
  [string]$ServiceName,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ServiceExePath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ServiceExePath
)

# Verificar si la aplicacion InstallUtil existe en la ruta especificada
if (Test-Path $InstallUtilPath) {
    # Verificar si el ejecutable existe en la ruta especificada
    if (Test-Path $ServiceExePath) {
      try {
        # Intentar iniciar el servicio o proceso
        & $InstallUtilPath $ServiceExePath
        net start $ServiceName
        Write-Output "Servicio instalado e iniciado correctamente."
        exit 0
      }
      catch {
        Write-Output "OcurriÃ³ un error al intentar instalar e iniciar el servicio: $($_.Exception.Message)"
        exit 1
      }
    }
    else {
      Write-Output "El servicio $ServiceExePath no existe."
      exit 1
    }
}
else {
  Write-Output "La aplicacion InstallUtil $InstallUtilPath no existe."
  exit 1
}