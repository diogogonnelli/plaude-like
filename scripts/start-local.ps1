param(
  [int]$Port = 8000
)

$root = Split-Path -Parent $PSScriptRoot

Write-Host "Building Laravel assets..."
Push-Location $root
try {
  npm run build
} finally {
  Pop-Location
}

Write-Host "Starting Laravel on http://localhost:$Port"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$root'; php artisan serve --host=127.0.0.1 --port=$Port"
