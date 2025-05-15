param(
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor del path del nuevo index(HTML). Ej: D:\websites\segurity\builds\YMS-Index\index.html")]
  [ValidateNotNullOrEmpty()]
  [string]$PathNewIndex,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor del path del sitio web. Ej: 'D:\websites\segurity\YMS\index.html")]
  [ValidateNotNullOrEmpty()]
  [string]$PathOldIndex,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor del path del nueva imagen del index. Ej: D:\websites\segurity\builds\YMS-Index\migration.png")]
  [ValidateNotNullOrEmpty()]
  [string]$PathNewIndexImg,
  [Parameter(Mandatory = $true, HelpMessage = "Por favor ingrese el valor del path del sitio web. Ej: D:\websites\segurity\YMS")]
  [ValidateNotNullOrEmpty()]
  [string]$WebSiteFolder
)

try {
    
    if(-not (Test-Path -Path "$PathNewIndex"))
    {
        Write-Host "No existe el path index new: $PathNewIndex"
        exit 1
    }

    $folderExistsServer = Test-Path -Path "$WebSiteFolder"
    If ($folderExistsServer -and ($WebSiteFolder.Length -gt 6)){

        if (Test-Path -Path ("$PathOldIndex")) {
            Remove-Item -Path ("$PathOldIndex")
        }

        Move-Item -Path "$PathNewIndex" -Destination "$WebSiteFolder"
        Move-Item -Path "$PathNewIndexImg" -Destination "$WebSiteFolder"
        
        Write-Host "La eliminacion y reemplazo del index fue exitosa. En caso de error, realizar rollback"
    } else {
        Write-Host "No paso las validaciones de ruta"
        exit 1
    }

} catch {
  Write-Host "Ocurrió un error: $($_.Exception.Message)"
  exit 1
}
