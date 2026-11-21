<#
.SYNOPSIS
  Builds the RoboRef Flutter Web app and deploys it to Cloudflare Workers with Static Assets.
.PARAMETER Environment
  The Cloudflare deployment environment ('test' or 'live'). Default: test.
.PARAMETER SkipBuild
  Skips the Flutter web build and deploys directly using existing artifacts in app/build/web.
.PARAMETER SkipWebBuild
  Alias for -SkipBuild; skips the Flutter web build (uses existing app/build/web).
.EXAMPLE
  .\scripts\deploy.ps1 test
  .\scripts\deploy.ps1 live
  .\scripts\deploy.ps1 test -SkipBuild
#>
param (
    [ValidateSet("test", "live")]
    [string]$Environment = "test",
    [switch]$SkipBuild,
    [switch]$SkipWebBuild
)

$ErrorActionPreference = "Stop"

$rootDir = Join-Path $PSScriptRoot ".."

# Step 1: Flutter Web PWA build
if (-not $SkipBuild -and -not $SkipWebBuild) {
    Write-Host ">>> Step 1/2: Building Flutter Web PWA for $Environment..." -ForegroundColor Cyan
    & "$PSScriptRoot\build.ps1" web "--dart-define=APP_ENV=$Environment"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter web build failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} else {
    Write-Host ">>> Step 1/2: Skipping web build (using existing app/build/web)..." -ForegroundColor Yellow
}

# Step 2: Cloudflare deployment (Web Assets)
Write-Host "`n>>> Step 2/2: Deploying RoboRef Web to Cloudflare ($Environment environment)..." -ForegroundColor Cyan
Push-Location $rootDir
try {
    npx wrangler deploy --env $Environment
} finally {
    Pop-Location
}
