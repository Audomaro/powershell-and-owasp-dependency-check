param (
    [Parameter(Mandatory = $true)]
    [string]$ApplicationPath
)

# Validar ruta
if (-not (Test-Path $ApplicationPath)) {
    Write-Error "❌ The specified path does not exist: $ApplicationPath"
    exit 1
}

# Validar herramientas
if (-not (Get-Command "syft" -ErrorAction SilentlyContinue)) {
    Write-Error "⚠️ Syft is not installed or not in PATH."
    exit 1
}

# Resolver ruta y definir archivo de salida
$ApplicationPath = Resolve-Path $ApplicationPath
$SBOM_FILE = Join-Path $ApplicationPath "sbom.json"

Write-Host "📦 Generating SBOM (.NET Standard + Angular) at: $ApplicationPath"

# Patrones de exclusión
$excludePaths = @(
    "**/*.ts", "**/*.html", "**/*.scss", "**/*.md", "**/*.json", "**/*.log",
    "**/*.cs", "**/*.vb", "**/*.designer.cs", "**/*.resx",
    "**/bin/**", "**/obj/**", "**/.vs/**", "**/dist/**", "**/coverage/**",
    "**/TestResults/**", "**/Debug/**", "**/Release/**", "**/node_modules/**", "**/packages/**"
)

# Construir argumentos de exclusión
$excludeArgs = @()
foreach ($pattern in $excludePaths) {
    $excludeArgs += "--exclude"
    $excludeArgs += $pattern
}

# Cambiar al directorio de trabajo
Push-Location $ApplicationPath
try {
    $syftOutput = & syft "dir:." --output cyclonedx-json @excludeArgs
    $syftOutput | Out-File -FilePath $SBOM_FILE -Encoding utf8
    Write-Host "✅ SBOM successfully generated at: $SBOM_FILE"
}
catch {
    Write-Error "❌ Error generating SBOM: $_"
}
finally {
    Pop-Location
}
