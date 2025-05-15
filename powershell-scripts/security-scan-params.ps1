param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$Params
)

Write-Host "Ejecutando Dependency Check, parametros: $($Params)"
& "dependency-check.bat" $Params
