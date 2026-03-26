param(
  [string]$BackendUrl = "http://localhost:8787"
)

Write-Host "Checking backend health..."
try {
  $backend = Invoke-RestMethod -Uri "$BackendUrl/health" -Method Get
  $backend | ConvertTo-Json -Depth 4
} catch {
  Write-Error "Backend healthcheck failed: $($_.Exception.Message)"
}
