param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ServiceExePath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ServiceExePath
)

# Verificar si el ejecutable existe en la ruta especificada
if (Test-Path $ServiceExePath) {
  try {
    # Intentar iniciar el servicio o proceso
    & $ServiceExePath install start
    Write-Output "Servicio instalado e iniciado correctamente."
    exit 0
  }
  catch {
    Write-Output "Ocurrió un error al intentar instalar e iniciar el servicio: $($_.Exception.Message)"
    exit 1
  }
}
else {
  Write-Output "El servicio $ServiceExePath no existe."
  exit 1
}
