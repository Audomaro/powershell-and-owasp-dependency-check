param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para WebsitesFolderWeb.")]
  [ValidateNotNullOrEmpty()]
  [string]$WebsitesFolderWeb,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para BannerRedirectPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$BannerRedirectPath
)

try {
  # Verificar si la ruta de la carpeta web es válida y contiene "D:"
  if (Test-Path -Path $WebsitesFolderWeb -and $WebsitesFolderWeb.Length -gt 6 -and $env:WEBSITES_FOLDER_WEB.Contains("D:")) {

    # Rutas de los archivos antiguos
    $oldBannerIndexFilePath = "$WebsitesFolderWeb\index.html"
    $oldBannerNotificacionJSFilePath = "$WebsitesFolderWeb\notificacion-mantenimiento.js"

    # Eliminar los archivos antiguos si existen
    if (Test-Path -Path $oldBannerIndexFilePath) {
      Write-Host "Eliminando archivo antiguo: index.html"
      Remove-Item -Path $oldBannerIndexFilePath
    }
    else {
      Write-Host "El archivo index.html no existe."
      exit 1
    }

    if (Test-Path -Path $oldBannerNotificacionJSFilePath) {
      Write-Host "Eliminando archivo antiguo: notificacion-mantenimiento.js"
      Remove-Item -Path $oldBannerNotificacionJSFilePath
    }

    # Rutas de los nuevos archivos
    $newBannerIndexFilePath = "$WebsitesFolderWeb\index.html"
    $newBannerNotificacionJSFilePath = "$WebsitesFolderWeb\notificacion-mantenimiento.js"

    # Mover los archivos nuevos
    Write-Host "Moviendo nuevos archivos..."
    Move-Item -Path $newBannerIndexFilePath -Destination $WebsitesFolderWeb
    Move-Item -Path $newBannerNotificacionJSFilePath -Destination $WebsitesFolderWeb

    # Eliminar la carpeta de redirección
    if (Test-Path -Path $BannerRedirectPath) {
      Write-Host "Eliminando la ruta de redirección: $BannerRedirectPath"
      Remove-Item -Path $BannerRedirectPath -Recurse
    }

    Write-Host "Proceso completado correctamente."
  }
  else {
    Write-Host "No se pasaron las validaciones de ruta."
    exit 1
  }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}

