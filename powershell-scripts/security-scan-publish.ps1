param (
  [string]$ReportsPath = "reports",
  [string]$PublicPath = "public",
  [string]$IndexFileName = "index.html"
)

# Verificar si la carpeta de destino existe, si no, crearla
if (-not (Test-Path -Path $PublicPath)) {
  New-Item -Path $PublicPath -ItemType Directory | Out-Null
}

# Mover archivos desde la carpeta de reportes al destino
$Files = Get-ChildItem -Path $ReportsPath -File -ErrorAction SilentlyContinue

if ($Files) {
  foreach ($File in $Files) {
    Move-Item -Path $File.FullName -Destination $PublicPath -Force
  }
  Write-Host "Archivos movidos de '$ReportsPath' a '$PublicPath'."
}
else {
  Write-Warning "No se encontraron archivos en '$ReportsPath'."
}

# Generar el archivo index.html
$IndexFilePath = Join-Path -Path $PublicPath -ChildPath $IndexFileName
$FilesInPublic = Get-ChildItem -Path $PublicPath -File | Where-Object { $_.Name -ne $IndexFileName }

# Crear contenido HTML para el índice
$IndexContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dependency Check Reports</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            color: #333;
            margin: 20px;
            padding: 20px;
        }
        h1 {
            text-align: left;
        }
        ul {
            padding: 0;
        }
        li {
            margin: 5px 0;
            font-size: 16px;
        }
        a {
            text-decoration: none;
            color: #4169e1;
            font-weight: bold;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <h1>Dependency Check Reports</h1>
    <ul>
"@

# Agrupar archivos por nombre base
$GroupedFiles = @{}
foreach ($File in $FilesInPublic) {
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($File)

    if (-not $GroupedFiles.ContainsKey($BaseName)) {
        $GroupedFiles[$BaseName] = @()
    }
    $GroupedFiles[$BaseName] += "<a href='./$($File.Name)'>$(($File.Extension) -replace '^\.','')</a>"
}

# Construir la lista de reportes con sus formatos disponibles
foreach ($BaseName in $GroupedFiles.Keys) {
    $IndexContent += "<li>${BaseName}: " + ($GroupedFiles[$BaseName] -join " | ") + "</li>`n"
}

$IndexContent += @"
    </ul>
</body>
</html>
"@

# Guardar el contenido en index.html
Set-Content -Path $IndexFilePath -Value $IndexContent
Write-Host "Archivo index.html generado en '$IndexFilePath'."
