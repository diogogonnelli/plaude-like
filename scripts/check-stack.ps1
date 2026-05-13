param(
  [string]$BaseUrl = "http://localhost:8000"
)

Write-Host "Checking Laravel API health..."
try {
  $health = Invoke-RestMethod -Uri "$BaseUrl/api/health" -Method Get
  $health | ConvertTo-Json -Depth 4
} catch {
  Write-Error "Laravel healthcheck failed: $($_.Exception.Message)"
}
