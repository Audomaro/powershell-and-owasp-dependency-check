param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ServiceName.")]
  [ValidateNotNullOrEmpty()]
  [string]$ServiceName
)

try {
    # Intentar iniciar el servicio o proceso
    net stop $ServiceName
    Write-Output "Servicio detenido correctamente."
    exit 0
}
catch {
    Write-Output "OcurriÃ³ un error al intentar detener el servicio: $($_.Exception.Message)"
    exit 1
}
