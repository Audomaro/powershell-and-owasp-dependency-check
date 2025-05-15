param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para WebSite.")]
  [ValidateNotNullOrEmpty()]
  [string]$WebSite,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para IisAppName.")]
  [ValidateNotNullOrEmpty()]
  [string]$IisAppName
)

Import-Module WebAdministration

try {
  # Definir la ruta de la aplicación IIS
  $appPath = "/$IisAppName"

  # Comprobar si la aplicación existe
  $existingApp = Get-WebApplication -Site $WebSite | Where-Object { $_.Path -eq $appPath }

  if ($existingApp) {
    # Eliminar la aplicación de IIS
    Remove-WebApplication -Site $WebSite -Name $IisAppName
    Write-Host "La aplicación '$IisAppName' ha sido desinstalada correctamente del sitio '$WebSite'."
  }
  else {
    Write-Host "La aplicación '$IisAppName' no se encuentra en el sitio '$WebSite'."
  }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
