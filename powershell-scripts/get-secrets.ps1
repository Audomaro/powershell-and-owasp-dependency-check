param (
  [Parameter(Mandatory = $true)]
  [string]$ReleasePath,

  [Parameter(Mandatory = $true)]
  [string]$tokens  # Ahora es string (JSON)
)

if (-not (Test-Path $ReleasePath)) {
  Write-Error "La carpeta '$ReleasePath' no existe."
  exit 1
}

# Convertir string JSON a objeto de PowerShell
try {
  $tokensObj = $tokens | ConvertFrom-Json
}
catch {
  Write-Error "El parámetro 'tokens' no contiene JSON válido: $_"
  exit 1
}

# Buscar archivos .config
$configFiles = Get-ChildItem -Path $ReleasePath -Filter *.config -Recurse

if ($configFiles.Count -eq 0) {
  Write-Host "No se encontraron archivos .config en '$ReleasePath'."
  exit 1
}

foreach ($file in $configFiles) {
  Write-Host "Procesando '$($file.FullName)'..."

  try {
    $content = Get-Content $file.FullName -Raw

    foreach ($key in $tokensObj.PSObject.Properties.Name) {
      $escapedKey = [Regex]::Escape($key)
      $value = $tokensObj.$key

      $content = [Regex]::Replace(
        $content,
        $escapedKey,
        $value,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
      )
    }

    Set-Content -Path $file.FullName -Value $content
    Write-Host "Tokens reemplazados correctamente en '$($file.Name)'."
  }
  catch {
    Write-Error "Error al procesar '$($file.FullName)': $_"
    exit 1
  }
}
