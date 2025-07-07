function RunSecScan {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$WorkDir,

        [Parameter(Mandatory = $false)]
        [string]$excludePaths  # Exclusiones personalizadas separadas por coma
    )

    # Ruta de salida del reporte CSV
    $outputCsv = Join-Path -Path $WorkDir -ChildPath "${ProjectName}.csv"

    # Exclusiones por defecto comunes para Node.js, .NET, Java y Angular
    $defaultExcludes = @(
        "**/node_modules/**",     # Node.js
        "**/packages/**",         # .NET NuGet packages
        "**/bin/**",              # .NET / Java / Angular build folder
        "**/obj/**",              # .NET intermediate build files
        "**/target/**",           # Maven/Java
        "**/dist/**",             # Angular/Node.js
        "**/build/**"             # Gradle/JavaScript
    )

    # Convertir exclusiones adicionales en lista (si se proporcionan)
    $customExcludes = @()
    if ($excludePaths) {
        $customExcludes = $excludePaths.Split(",") | ForEach-Object { $_.Trim() }
    }

    # Unir exclusiones por defecto y personalizadas, sin duplicados ni vacíos
    $allExcludes = ($defaultExcludes + $customExcludes) | Where-Object { $_ -ne "" } | Sort-Object -Unique

    # Construir argumentos de exclusión
    $excludeArgs = @()
    foreach ($path in $allExcludes) {
        $excludeArgs += "--exclude"
        $excludeArgs += $path
    }

    # Construir todos los argumentos del comando
    $args = @(
        "--project", $ProjectName,
        "-s", $ProjectPath,
        "-o", $outputCsv,
        "-n",
        "--format", "CSV",
        "--disableOssIndex",
        "--disableComposer",
        "--disableArchive",
        "--disableJar",
        "--disableAutoconf",
        "--disableCmake",
        "--disablePip",
        "--disablePipfile",
        "--nodeAudit",
        "--disableYarnAudit",
        "--disableAssembly",
        "--disableCentral",
        "--disableRetireJS",
        "--enableExperimental"
    ) + $excludeArgs

    # Ejecutar Dependency Check
    & "dependency-check.bat" @args
}
