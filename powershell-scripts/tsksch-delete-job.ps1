param (
  [Parameter(Mandatory = $true)]
  [string]$JobName
)

try {
  # Conectar al servicio de tareas programadas
  $service = New-Object -ComObject Schedule.Service
  $service.Connect()

  # Obtener la carpeta dev-team
  $taskFolderPath = "\mexico-apps"
  $taskFolder = $service.GetFolder($taskFolderPath)

  # Intentar obtener la tarea
  try {
    $task = $taskFolder.GetTask($JobName)
  }
  catch {
    throw "La tarea '$JobName' no existe en la carpeta '$taskFolderPath'."
  }

  # Detener la tarea si está en ejecución
  if ($task.State -eq 4) {
    try {
      $task.Stop()
      Write-Host "La tarea '$JobName' estaba en ejecuci�n y ha sido detenida."
    }
    catch {
      throw "No se pudo detener la tarea '$JobName'."
    }
  }

  # Eliminar la tarea
  try {
    $taskFolder.DeleteTask($JobName, 0)
    Write-Host "Tarea '$JobName' eliminada exitosamente de la carpeta '$taskFolderPath'."
    exit 0
  }
  catch {
    throw "Error al intentar eliminar la tarea '$JobName'."
  }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
