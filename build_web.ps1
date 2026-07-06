$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvPath = Join-Path $ProjectRoot ".env"
$ExamplePath = Join-Path $ProjectRoot ".env.example"

if (-not (Test-Path $EnvPath)) {
  Copy-Item $ExamplePath $EnvPath
  Write-Host "Created .env from .env.example." -ForegroundColor Yellow
  Write-Host "Edit .env with your AWS values, then run .\build_web.ps1 again." -ForegroundColor Yellow
  exit 1
}

$values = @{}
Get-Content $EnvPath | ForEach-Object {
  $line = $_.Trim()
  if ($line -eq "" -or $line.StartsWith("#")) {
    return
  }
  $parts = $line.Split("=", 2)
  if ($parts.Count -eq 2) {
    $values[$parts[0].Trim()] = $parts[1].Trim()
  }
}

foreach ($key in @("AWS_REGION", "AWS_API_BASE_URL", "AWS_USER_POOL_CLIENT_ID")) {
  if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key]) -or $values[$key].StartsWith("YOUR_")) {
    throw "Missing $key in .env. Fill it with the value from AWS deploy output."
  }
}

flutter build web `
  --dart-define=AWS_REGION=$($values["AWS_REGION"]) `
  --dart-define=AWS_API_BASE_URL=$($values["AWS_API_BASE_URL"]) `
  --dart-define=AWS_USER_POOL_CLIENT_ID=$($values["AWS_USER_POOL_CLIENT_ID"])
