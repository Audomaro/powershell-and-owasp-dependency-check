param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ServiceExePath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ServiceExePath
)

# Verificar si el ejecutable existe en la ruta especificada
if (Test-Path $ServiceExePath) {
  try {
    # Intentar iniciar el servicio o proceso
    & $ServiceExePath stop
    Write-Output "Servicio detenido correctamente."
    exit 0
  }
  catch {
    Write-Output "Ocurrió un error al intentar detener el servicio: $($_.Exception.Message)"
    exit 1
  }
}
else {
  Write-Output "El servicio $ServiceExePath no existe."
  exit 0
}

