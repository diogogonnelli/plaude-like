param(
  [string]$BackendUrl = "http://localhost:8787"
)

$root = Split-Path -Parent $PSScriptRoot

Write-Host "Starting backend on $BackendUrl"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$root\backend'; if (-not (Test-Path '.env')) { Copy-Item '.env.example' '.env' }; npm start"

Write-Host "Starting Flutter web app"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$root\app'; flutter run -d chrome --dart-define=BACKEND_BASE_URL=$BackendUrl"
