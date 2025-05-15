param (
  [Parameter(Mandatory = $true)]
  [string]$ReleasePath,

  [Parameter(Mandatory = $true)]
  [hashtable]$tokens
)

if (-not (Test-Path $ReleasePath)) {
  Write-Error "La carpeta '$ReleasePath' no existe."
  exit 1
}

# Buscar todos los archivos .config en la carpeta (recursivamente si se desea)
$configFiles = Get-ChildItem -Path $ReleasePath -Filter *.config -Recurse

if ($configFiles.Count -eq 0) {
  Write-Host "No se encontraron archivos .config en '$ReleasePath'."
  exit 1
}

foreach ($file in $configFiles) {
  Write-Host "Procesando '$($file.FullName)'..."

  try {
    # Leer el contenido como una sola cadena
    $content = Get-Content $file.FullName -Raw

    foreach ($key in $tokens.Keys) {
      $escapedKey = [Regex]::Escape($key)
      $value = $tokens[$key]

      # Reemplazo insensible a mayúsculas y minúsculas
      $content = [Regex]::Replace(
        $content,
        $escapedKey,
        $value,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
      )
    }

    # Guardar los cambios
    Set-Content -Path $file.FullName -Value $content
    Write-Host "Tokens reemplazados correctamente en '$($file.Name)'."
  }
  catch {
    Write-Error "Error al procesar '$($file.FullName)': $_"
    exit 1
  }
}
