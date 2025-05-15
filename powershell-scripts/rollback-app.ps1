param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para BackupPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$BackupPath,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para PublishPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$PublishPath,
  [Parameter(Mandatory = $false, HelpMessage = "Por favor ingrese el valor para ExcludeDirectories.")]
  [string[]]$ExcludeDirectories
)

try {
  Write-Host "Iniciando proceso de rollback..."

  # Obtener el backup más reciente
  $recentBackupFolder = Get-ChildItem -Path $BackupPath | Sort-Object -Property LastWriteTime -Descending | Where-Object { $_.Name -like "bk*" } | Select-Object -First 1

  # Verificar si se encontró un backup reciente
  if ($recentBackupFolder) {
    Write-Host "Backup más reciente encontrado: $recentBackupFolder"

    # Verificar si la carpeta de backup existe
    $backupFolderPath = "$BackupPath\$($recentBackupFolder.Name)"
    if (Test-Path -Path $backupFolderPath) {
      # Verificar si la carpeta de publicación existe
      if (Test-Path -Path $PublishPath) {
        Write-Host "Eliminando archivos antiguos de la carpeta de publicación, excluyendo ciertos directorios..."

        # Construimos las rutas completas para exclusión
        $excludePaths = @()
        if ($ExcludeDirectories) {
          foreach ($dir in $ExcludeDirectories) {
            $fullExcludePath = (Join-Path -Path $PublishPath -ChildPath $dir).ToLower()
            $excludePaths += $fullExcludePath
          }
        }

        # Iteramos sobre los elementos en PublishPath
        Get-ChildItem -Path $PublishPath -Recurse | ForEach-Object {
          $itemPath = $_.FullName.ToLower()

          if ($excludePaths -notcontains $itemPath -and -not ($excludePaths | Where-Object { $itemPath -like "$_*" })) {
            Write-Host "Eliminando: $itemPath"
            Remove-Item -Path $_.FullName -Recurse -Force
          }
          else {
            Write-Host "Excluyendo: $itemPath"
          }
        }
      }
      else {
        Write-Host "La carpeta de publicación no existe."
        exit 1
      }

      # Realizar el rollback
      Write-Host "Restaurando archivos del backup en la carpeta de publicación..."
      Copy-Item "$backupFolderPath\*" -Destination $PublishPath -Recurse -Force

      Write-Host "Rollback finalizado correctamente."
      exit 0
    }
    else {
      Write-Host "No existe la carpeta de backup más reciente: $backupFolderPath"
      exit 1
    }
  }
  else {
    Write-Host "No se encontró un backup reciente."
    exit 1
  }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
