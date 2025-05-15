param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ZipReleasePath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ZipReleasePath,

  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para PublishPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$PublishPath,

  [Parameter(Mandatory = $false, HelpMessage = "Por favor ingrese el valor para ExcludeDirectories.")]
  [string[]]$ExcludeDirectories
)

try {
  # Verificar si el archivo ZIP existe
  if (-not (Test-Path -Path $ZipReleasePath)) {
    Write-Host "No existe el archivo ZIP en la ruta: $ZipReleasePath"
    exit 1  # Salir si no se encuentra el archivo ZIP
  }

  # Verificar si la carpeta de publicación existe, si no, crearla
  if (-not (Test-Path -Path $PublishPath)) {
    Write-Host "La ruta de publicación no existe, creando..."
    New-Item -ItemType Directory -Path $PublishPath | Out-Null
  }

  # Obtener todos los elementos existentes en la carpeta de publicación
  $existingItems = Get-ChildItem -Path $PublishPath -Recurse
  $excludePaths = @()

  # Construir las rutas completas de exclusión si hay directorios especificados
  if ($ExcludeDirectories) {
    foreach ($dir in $ExcludeDirectories) {
      # Convertir las rutas a minúsculas para evitar problemas de comparación
      $excludePaths += (Join-Path -Path $PublishPath -ChildPath $dir).ToLower()
    }
  }

  # Iterar sobre los elementos existentes en la carpeta de publicación
  foreach ($item in $existingItems) {
    $itemPath = $item.FullName.ToLower()  # Convertir la ruta a minúsculas

    # Eliminar los elementos que no estén en la lista de exclusión
    if ($excludePaths -notcontains $itemPath -and -not ($excludePaths | Where-Object { $itemPath -like "$_*" })) {
      Write-Host "Eliminando: $itemPath"
      Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
    } else {
      Write-Host "Excluyendo: $itemPath"
    }
  }

  # Descomprimir el archivo ZIP en la carpeta de publicación
  Write-Host "Descomprimiendo el archivo ZIP en la ruta: $PublishPath"
  Expand-Archive -LiteralPath $ZipReleasePath -DestinationPath $PublishPath -Force

  # Eliminar el archivo ZIP después de descomprimirlo
  Remove-Item -Path $ZipReleasePath
  Write-Host "El archivo ZIP ha sido descomprimido y eliminado correctamente."
}
catch {
  # Capturar cualquier error y mostrar el mensaje de la excepción
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1  # Salir con código de error
}
