param (
  [Parameter(Mandatory = $true)]
  [string]$JobName,

  [Parameter(Mandatory = $true)]
  [string]$ActionPath,

  [Parameter(Mandatory = $false)]
  [string]$Arguments,

  [Parameter(Mandatory = $true)]
  [ValidateSet("Daily", "Weekly", "Monthly", "Once", "Hourly", "Minutes")]
  [string]$ScheduleType,

  [Parameter(Mandatory = $true)]
  [datetime]$StartTime,

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 59)]
  [int]$MinutesInterval = 5,

  [Parameter(Mandatory = $false)]
  [ValidateRange(0, 6)]
  [int]$DayOfWeek = 1,

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 31)]
  [int]$DayOfMonth = 1
)

try {
  # Crear la carpeta dev-team si no existe
  $taskFolderPath = "\mexico-apps"
  $service = New-Object -ComObject Schedule.Service
  $service.Connect()
  $rootFolder = $service.GetFolder("\")

  try {
    $taskFolder = $rootFolder.GetFolder($taskFolderPath)
  }
  catch {
    $rootFolder.CreateFolder($taskFolderPath) | Out-Null
    $taskFolder = $rootFolder.GetFolder($taskFolderPath)
  }

  # Crear una nueva definición de tarea
  $taskDefinition = $service.NewTask(0)

  # Registrar la acción
  $action = $taskDefinition.Actions.Create(0)
  $action.Path = $ActionPath
  $action.Arguments = $Arguments

  # Configurar el trigger según ScheduleType
  switch ($ScheduleType) {
    "Daily" {
      $trigger = $taskDefinition.Triggers.Create(1)
      $trigger.DaysInterval = 1
    }
    "Weekly" {
      if ($null -eq $DayOfWeek) {
        throw "Debe especificar un valor para DayOfWeek entre 0 (Domingo) y 6 (S�bado) para una tarea semanal."
      }
      $trigger = $taskDefinition.Triggers.Create(3)
      $trigger.DaysOfWeek = 1 -shl $DayOfWeek
      $trigger.WeeksInterval = 1
    }
    "Monthly" {
      if ($null -eq $DayOfMonth) {
        throw "Debe especificar un valor para DayOfMonth entre 1 y 31 para una tarea mensual."
      }
      $trigger = $taskDefinition.Triggers.Create(6)
      $trigger.DaysOfMonth = $DayOfMonth
    }
    "Once" {
      $trigger = $taskDefinition.Triggers.Create(0)
    }
    "Hourly" {
      $trigger = $taskDefinition.Triggers.Create(1)
      $trigger.Repetition.Interval = "PT1H"
    }
    "Minutes" {
      $trigger = $taskDefinition.Triggers.Create(1)
      $trigger.Repetition.Interval = "PT${MinutesInterval}M"
      $trigger.Repetition.Duration = "P1D" # Durante todo el d�a
    }
  }

  $trigger.StartBoundary = $StartTime.ToString("yyyy-MM-ddTHH:mm:ss")
  #$taskDefinition.Principal.UserId = "$env:UserDomain\$env:UserName"
  $taskDefinition.Principal.UserId = "SYSTEM"
  $taskDefinition.Principal.LogonType = 2
  $taskDefinition.Settings.Enabled = $true

  # Registrar la tarea
  $taskFolder.RegisterTaskDefinition($JobName, $taskDefinition, 6, $null, $null, 3)
  Write-Host "Tarea '$JobName' creada exitosamente en la carpeta '$taskFolderPath'."
  exit 0
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
