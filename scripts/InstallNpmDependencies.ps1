function InstallNpmDependencies {
    param (
        [string]$ProjectPath
    )

    $packageFiles = Get-ChildItem -Path $ProjectPath -Filter "package.json" -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -notmatch "\\node_modules\\" }

    if ($packageFiles.Count -gt 0) {
        foreach ($pkg in $packageFiles) {
            $pkgFolder = Split-Path $pkg.FullName -Parent
            $nodeModulesPath = Join-Path $pkgFolder "node_modules"

            if (-not (Test-Path $nodeModulesPath)) {
                Write-Host "Found package.json in ${pkgFolder} - Running 'npm ci --silent'..." -ForegroundColor $Env:COLOR_INFO

                Push-Location $pkgFolder
                try {
                    npm ci --silent
                    Write-Host "'npm ci --silent' completed successfully in ${pkgFolder}" -ForegroundColor $Env:COLOR_SUCC
                }
                catch {
                    Write-Warning "Error during 'npm ci --silent' in ${pkgFolder}: $_"
                }
                Pop-Location
            }
            else {
                Write-Host "node_modules already exists in ${pkgFolder} - Skipping 'npm ci --silent'." -ForegroundColor $Env:COLOR_SKIP
            }
        }
    }
    else {
        Write-Host "No package.json files found in ${ProjectPath} - Skipping npm ci --silentation." -ForegroundColor $Env:COLOR_SKIP
    }
}
