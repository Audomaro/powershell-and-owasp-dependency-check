param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para PublishPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$PublishPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para BackupPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$BackupPath,
  [Parameter(Mandatory = $false, HelpMessage = "Por favor ingrese el valor para ExcludeDirectories.")]
  [string[]]$ExcludeDirectories
)

try {
  # Comprobamos si la ruta de publicación existe, si no, la creamos
  if (!(Test-Path -PathType Container $PublishPath)) {
    New-Item -ItemType Directory -Path $PublishPath
    Write-Host "Se creó el directorio en la ruta: $PublishPath"
  }

  # Comprobamos si la ruta de backup existe, si no, la creamos
  if (!(Test-Path -PathType Container $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath
    Write-Host "Se creó el directorio en la ruta: $BackupPath"
  }

  # Comprobamos si hay archivos para respaldar en la ruta de publicación
  $directoryInfo = Get-ChildItem $PublishPath | Measure-Object
  if ($directoryInfo.Count -eq 0) {
    Write-Host "No se encontraron archivos para respaldar."
    exit 0
  }

  Write-Host "Iniciando proceso de respaldo..."

  # Eliminamos los backups antiguos de más de 3 días
  Write-Host "Verificando antigüedad de backups..."
  Get-ChildItem -Path $BackupPath -Directory | ForEach-Object {
    $currentDateTime = Get-Date
    $folderCreationDate = $_.CreationTime.Date
    $dateDifference = New-TimeSpan -Start $folderCreationDate -End $currentDateTime

    Write-Host "Verificando: $_.FullName"

    if ($dateDifference.Days -gt 3) {
      $backupFolderPath = $_.FullName
      Write-Host "Eliminado backup: $backupFolderPath"
      Remove-Item -Path $backupFolderPath -Recurse
    }
  }

  Write-Host "Backups antiguos eliminados..."

  # Generamos un nombre con fecha y hora para el nuevo backup
  $timestamp = Get-Date -Format 'MM-dd-yy_HHmmss'
  $backupDestination = "$BackupPath\bk_$timestamp"
  New-Item -ItemType Directory -Path $backupDestination -Force
  Write-Host "Generando backup en: $backupDestination"

  # Construimos las rutas completas de exclusión
  $excludePaths = @()
  if ($ExcludeDirectories) {
    foreach ($dir in $ExcludeDirectories) {
      $fullExcludePath = (Join-Path -Path $PublishPath -ChildPath $dir).ToLower()
      $excludePaths += $fullExcludePath
    }
  }

  # Realizamos el respaldo excluyendo los directorios indicados
  Get-ChildItem -Path $PublishPath -Recurse | ForEach-Object {
    $itemPath = $_.FullName.ToLower()

    # Verificamos si el elemento está dentro de las rutas a excluir
    if ($excludePaths -notcontains $itemPath -and -not ($excludePaths | Where-Object { $itemPath -like "$_*" })) {
      $destination = $itemPath -replace [regex]::Escape($PublishPath.ToLower()), $backupDestination
      if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $destination -Force
      }
      else {
        Copy-Item -Path $_.FullName -Destination $destination
      }
    }
    else {
      Write-Host "Excluyendo: $itemPath"
    }
  }

  Write-Host "Backup generado correctamente en: $backupDestination"

  exit 0
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
