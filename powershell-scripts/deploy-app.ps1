param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para PublishPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$PublishPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para ReleasePath.")]
  [ValidateNotNullOrEmpty()]
  [string]$ReleasePath,
  [Parameter(Mandatory = $false, HelpMessage = "Por favor ingrese el valor para ExcludeDirectories.")]
  [string[]]$ExcludeDirectories
)

try {
  # Verificar si la ruta de release existe
  if (!(Test-Path -PathType Container $ReleasePath)) {
    Write-Host "No se encontró la ruta: $ReleasePath"
    exit 1
  }

  # Comprobar si hay archivos para publicar en la ruta de release
  $directoryInfo = Get-ChildItem $ReleasePath | Measure-Object
  if ($directoryInfo.Count -eq 0) {
    Write-Host "No se encontraron archivos por publicar."
    exit 0
  }

  # Verificar si el folder de publicación existe en el servidor
  if (Test-Path -PathType Container $PublishPath) {
    # Si hay archivos en la carpeta de publicación, limpiarlos excluyendo los indicados
    $existingItems = Get-ChildItem -Path $PublishPath

    if ($existingItems.Count -eq 0) {
      Write-Host "No se encontraron archivos dentro de la carpeta: $PublishPath"
    }
    else {
      Write-Host "Eliminando archivos antiguos en $PublishPath, excluyendo ciertos directorios..."

      # Construimos las rutas completas para exclusión
      $excludePaths = @()
      if ($ExcludeDirectories) {
        foreach ($dir in $ExcludeDirectories) {
          $fullExcludePath = (Join-Path -Path $PublishPath -ChildPath $dir).ToLower()
          $excludePaths += $fullExcludePath
        }
      }

      # Iteramos sobre los elementos de la carpeta de publicación
      foreach ($item in $existingItems) {
        $itemPath = $item.FullName.ToLower()

        if ($excludePaths -notcontains $itemPath -and -not ($excludePaths | Where-Object { $itemPath -like "$_*" })) {
          Write-Host "Eliminando: $itemPath"
          Remove-Item -Path $item.FullName -Recurse -Force
        }
        else {
          Write-Host "Excluyendo: $itemPath"
        }
      }
    }

    # Copiar los archivos desde el release al folder de publicación
    Write-Host "Copiando archivos desde $ReleasePath hacia $PublishPath..."
    Copy-Item -Path "$ReleasePath\*" -Destination $PublishPath -Recurse -Force
    Write-Host "El proyecto se actualizó correctamente."
    exit 0
  }
  else {
    Write-Host "No se pudo actualizar el proyecto porque no se encontró la carpeta: $PublishPath"
    exit 1
  }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
