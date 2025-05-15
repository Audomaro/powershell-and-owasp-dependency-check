Param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para PublishPath.")]
  [ValidateNotNullOrEmpty()]
  [string]$PublishPath
)

try {
  # Verificar si el folder existe
  if (Test-Path -Path $PublishPath) {
    Write-Output "El folder existe en: $PublishPath. Procediendo a eliminar..."

    # Eliminar el folder y su contenido
    Remove-Item -Path $PublishPath -Recurse -Force
    Write-Output "El folder y su contenido han sido eliminados exitosamente."
    exit 0
  }
  else {
    Write-Output "El folder no existe en la ruta especificada: $PublishPath"
    exit 0
  }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}

