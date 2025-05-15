param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para WebSite.")]
  [ValidateNotNullOrEmpty()]
  [string]$WebSite,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para IisAppName.")]
  [ValidateNotNullOrEmpty()]
  [string]$IisAppName,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para AppPool.")]
  [ValidateNotNullOrEmpty()]
  [string]$AppPool,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para PhysicalPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$PhysicalPath
)

Import-Module WebAdministration

try {
  # Verificar si el sitio web existe
  $site = Get-Website -Name $WebSite -ErrorAction SilentlyContinue
  if (-not $site) {
    Write-Host "El sitio web '$WebSite' no existe."
    exit 1
  }

  # Definir las variables necesarias para la aplicación IIS
  $appPath = "/$IisAppName"

  # Comprobar si la aplicación ya existe
  $existingApp = Get-WebApplication -Site $WebSite | Where-Object { $_.Path -eq $appPath }

  if ($existingApp) {
    Write-Host "La aplicación '$IisAppName' ya existe en el sitio '$WebSite'."
  }
  else {
    # Crear la nueva aplicación con el Application Pool proporcionado (o el valor por defecto)
    New-WebApplication -Site $WebSite -Name $appPath -PhysicalPath $PhysicalPath -ApplicationPool $AppPool
    Write-Host "Aplicación '$IisAppName' creada en el sitio '$WebSite' usando el Application Pool '$AppPool'."
  }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
