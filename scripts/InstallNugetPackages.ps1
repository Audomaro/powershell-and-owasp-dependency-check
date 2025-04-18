function InstallNugetPackages {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $slnFiles = Get-ChildItem -Path $ProjectPath -Filter "*.sln" -Recurse -ErrorAction SilentlyContinue

    if ($slnFiles.Count -gt 0) {
        foreach ($sln in $slnFiles) {
            Write-Host "Running NuGet restore for ${sln.FullName}..." -ForegroundColor $Env:COLOR_INFO
            & nuget restore $sln.FullName | Out-Null
        }
        Write-Host "NuGet restore completed in ${ProjectPath}" -ForegroundColor $Env:COLOR_SUCC
    }
    else {
        Write-Host "No .sln files found in ${ProjectPath} - Skipping NuGet restore." -ForegroundColor $Env:COLOR_SKIP
    }
}
