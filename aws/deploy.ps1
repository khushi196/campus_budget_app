param(
  [string]$Region = "ap-south-1",
  [string]$StackName = "campus-budget",
  [string]$GeminiParameterName = "/campus-budget/gemini-api-key",
  [string]$GeminiApiKey = ""
)

$ErrorActionPreference = "Stop"
$AwsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $AwsDir
$EnvPath = Join-Path $ProjectRoot ".env"

function Require-Command($Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "$Name is not installed or not available in PATH."
  }
}

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

Require-Command "aws"
Require-Command "sam"
Require-Command "flutter"

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

Write-Host "Checking AWS account..." -ForegroundColor Cyan
aws sts get-caller-identity --region $Region | Out-Host

Write-Host "Saving Gemini key in AWS SSM Parameter Store..." -ForegroundColor Cyan
aws ssm put-parameter `
  --name $GeminiParameterName `
  --type SecureString `
  --value $GeminiApiKey `
  --overwrite `
  --region $Region | Out-Host

Write-Host "Building SAM app..." -ForegroundColor Cyan
Push-Location $AwsDir
try {
  sam build --template-file template.yaml

  Write-Host "Deploying AWS backend..." -ForegroundColor Cyan
  sam deploy `
    --stack-name $StackName `
    --region $Region `
    --capabilities CAPABILITY_IAM `
    --resolve-s3 `
    --parameter-overrides GeminiApiKeyParameterName=$GeminiParameterName
} finally {
  Pop-Location
}

Write-Host "Reading stack outputs..." -ForegroundColor Cyan
$outputsJson = aws cloudformation describe-stacks `
  --stack-name $StackName `
  --region $Region `
  --query "Stacks[0].Outputs" `
  --output json
$outputs = $outputsJson | ConvertFrom-Json

$apiUrl = ($outputs | Where-Object { $_.OutputKey -eq "ApiUrl" }).OutputValue
$clientId = ($outputs | Where-Object { $_.OutputKey -eq "UserPoolClientId" }).OutputValue

@"
AWS_REGION=$Region
AWS_API_BASE_URL=$apiUrl
AWS_USER_POOL_CLIENT_ID=$clientId
GEMINI_API_KEY=$GeminiApiKey
"@ | Set-Content -Path $envPath -Encoding UTF8

Write-Host ""
Write-Host "AWS is ready." -ForegroundColor Green
Write-Host "ApiUrl: $apiUrl"
Write-Host "Region: $Region"
Write-Host "UserPoolClientId: $clientId"
Write-Host ".env updated: $envPath"
Write-Host ""
Write-Host "Run Flutter web with:" -ForegroundColor Cyan
Write-Host "cd `"$ProjectRoot`""
Write-Host ".\run_web.ps1"
Write-Host ""
Write-Host "Build Flutter web with:" -ForegroundColor Cyan
Write-Host ".\build_web.ps1"
