function InstallNugetPackages {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    # Buscar todos los .sln ignorando carpetas 'packages'
    $slnFiles = Get-ChildItem -Path $ProjectPath -Filter "*.sln" -Recurse |
    Where-Object { $_.FullName -notmatch "\\packages\\.*" } |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter "*.sln" -ErrorAction SilentlyContinue } |
    Where-Object { $_ -ne $null }

    if ($slnFiles.Count -gt 0) {
        foreach ($sln in $slnFiles) {
            $slnDir = Split-Path $sln.FullName -Parent
            $packagesPath = Join-Path $slnDir "packages"

            if (Test-Path $packagesPath) {
                Write-Host "Found 'packages' folder in $slnDir - Skipping restore." -ForegroundColor $Env:COLOR_SKIP
                continue
            }

            Write-Host "Running NuGet restore for ${sln.FullName}..." -ForegroundColor $Env:COLOR_INFO
            & nuget restore $sln.FullName | Out-Null
        }

        Write-Host "NuGet restore completed in ${ProjectPath}" -ForegroundColor $Env:COLOR_SUCC
    }
    else {
        Write-Host "No .sln files found in ${ProjectPath} - Skipping NuGet restore." -ForegroundColor $Env:COLOR_SKIP
    }
}
