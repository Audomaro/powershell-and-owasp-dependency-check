param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ServiceName.")]
  [ValidateNotNullOrEmpty()]
  [string]$ServiceName
)

try {
    # Intentar iniciar el servicio o proceso
    net start $ServiceName
    Write-Output "Servicio iniciado correctamente."
    exit 0
}
catch {
    Write-Output "OcurriÃ³ un error al intentar iniciar el servicio: $($_.Exception.Message)"
    exit 1
}
