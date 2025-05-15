param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para PathIIS.")]
  [ValidateNotNullOrEmpty()]
  [string]$PathIISOrigen,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor para UrlDestination.")]
  [ValidateNotNullOrEmpty()]
  [string]$UrlDestination,
  [bool]$Disabled = $false
)

try {
    Import-Module WebAdministration -ErrorAction Stop

    Write-Host "URL origen: " + $PathIISOrigen
    Write-Host "URL destino: " + $UrlDestination
      
    if(Test-Path $PathIISOrigen)
    {
        if(!$Disabled)
        {
            Set-WebConfiguration system.webServer/httpRedirect "$PathIISOrigen" -Value @{enabled="true";destination="$UrlDestination";exactDestination="true";httpResponseStatus="Found"}
            Write-Host "Sitio web redireccionado"
        } else {
            Set-WebConfiguration system.webServer/httpRedirect "$PathIISOrigen" -Value @{enabled="false"}
            Write-Host "Redireccionamiento deshabilitado exitosamente"  
        }
    } else {
        Write-Host "Sitio web no encontrado, verifique el valor de PathIIS"
    }
}
catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
