<#
.SYNOPSIS
  Builds the RoboRef Server (Cloudflare Worker) and Flutter Web app, then deploys to Cloudflare Workers with Static Assets.
.PARAMETER Environment
  The Cloudflare deployment environment ('test' or 'live'). Default: test.
.PARAMETER SkipBuild
  Skips all builds (server and web) and deploys directly using existing artifacts.
.PARAMETER SkipWebBuild
  Skips the Flutter web build (uses existing app/build/web).
.PARAMETER SkipServerBuild
  Skips the server typecheck / compilation.
.EXAMPLE
  .\scripts\deploy.ps1 test
  .\scripts\deploy.ps1 live
  .\scripts\deploy.ps1 test -SkipBuild
  .\scripts\deploy.ps1 test -SkipWebBuild
#>
param (
    [ValidateSet("test", "live")]
    [string]$Environment = "test",
    [switch]$SkipBuild,
    [switch]$SkipWebBuild,
    [switch]$SkipServerBuild
)

$ErrorActionPreference = "Stop"

$rootDir = Join-Path $PSScriptRoot ".."

# Step 1: Server / Cloudflare Worker verification and build
if (-not $SkipBuild -and -not $SkipServerBuild) {
    Write-Host ">>> Step 1/3: Building & Typechecking Server (Cloudflare Worker)..." -ForegroundColor Cyan
    & "$PSScriptRoot\build.ps1" server
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Server build/typecheck failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} else {
    Write-Host ">>> Step 1/3: Skipping server build..." -ForegroundColor Yellow
}

# Step 2: Flutter Web PWA build
if (-not $SkipBuild -and -not $SkipWebBuild) {
    Write-Host "`n>>> Step 2/3: Building Flutter Web PWA for $Environment..." -ForegroundColor Cyan
    & "$PSScriptRoot\build.ps1" web "--dart-define=APP_ENV=$Environment"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter web build failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} else {
    Write-Host "`n>>> Step 2/3: Skipping web build (using existing app/build/web)..." -ForegroundColor Yellow
}

# Step 3: Cloudflare deployment (Worker + Web Assets)
Write-Host "`n>>> Step 3/3: Deploying to Cloudflare ($Environment environment)..." -ForegroundColor Cyan
Push-Location $rootDir
try {
    npx wrangler deploy --env $Environment
} finally {
    Pop-Location
}
