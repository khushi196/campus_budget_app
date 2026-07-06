param(
  [string]$Region = "ap-south-1",
  [string]$GeminiParameterName = "/campus-budget/gemini-api-key",
  [string]$GeminiApiKey = ""
)

$ErrorActionPreference = "Stop"
$AwsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $AwsDir
$EnvPath = Join-Path $ProjectRoot ".env"

function Read-EnvFile($Path) {
  $values = @{}
  if (-not (Test-Path $Path)) {
    return $values
  }
  Get-Content $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) {
      return
    }
    $parts = $line.Split("=", 2)
    if ($parts.Count -eq 2) {
      $values[$parts[0].Trim()] = $parts[1].Trim()
    }
  }
  return $values
}

function Test-PlaceholderKey($Value) {
  return $Value.StartsWith("YOUR_") -or $Value.StartsWith("PASTE_")
}

if (-not (Get-Command "aws" -ErrorAction SilentlyContinue)) {
  throw "aws is not installed or not available in PATH."
}

if ([string]::IsNullOrWhiteSpace($GeminiApiKey)) {
  $envValues = Read-EnvFile $EnvPath
  if ($envValues.ContainsKey("GEMINI_API_KEY") -and -not [string]::IsNullOrWhiteSpace($envValues["GEMINI_API_KEY"]) -and -not (Test-PlaceholderKey $envValues["GEMINI_API_KEY"])) {
    $GeminiApiKey = $envValues["GEMINI_API_KEY"]
  }
}

if ([string]::IsNullOrWhiteSpace($GeminiApiKey)) {
  $secureKey = Read-Host "Paste your Gemini API key" -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
  try {
    $GeminiApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

$GeminiApiKey = -join ($GeminiApiKey.Trim().ToCharArray() | Where-Object { -not [char]::IsControl($_) })
if ($GeminiApiKey.Length -lt 20 -or (Test-PlaceholderKey $GeminiApiKey)) {
  throw "Gemini API key looks invalid. Put the full key in .env as GEMINI_API_KEY=..."
}

aws ssm put-parameter `
  --name $GeminiParameterName `
  --type SecureString `
  --value $GeminiApiKey `
  --overwrite `
  --region $Region | Out-Null

Write-Host "Gemini key saved to $GeminiParameterName in $Region." -ForegroundColor Green
