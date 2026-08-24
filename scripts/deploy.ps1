<#
.SYNOPSIS
  Builds the RoboRef Flutter Web app and deploys to Cloudflare Workers with Static Assets.
.PARAMETER Environment
  The Cloudflare deployment environment ('test' or 'live'). Default: test.
.EXAMPLE
  .\scripts\deploy.ps1 test
  .\scripts\deploy.ps1 live
  .\scripts\deploy.ps1 test -SkipBuild
#>
param (
    [ValidateSet("test", "live")]
    [string]$Environment = "test",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$rootDir = Join-Path $PSScriptRoot ".."

if (-not $SkipBuild) {
    Write-Host ">>> Step 1/2: Building Flutter Web PWA..." -ForegroundColor Cyan
    & "$PSScriptRoot\build.ps1" web
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter web build failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} else {
    Write-Host ">>> Skipping web build (using existing app/build/web)..." -ForegroundColor Yellow
}

Write-Host "`n>>> Step 2/2: Deploying to Cloudflare ($Environment environment)..." -ForegroundColor Cyan
Push-Location $rootDir
try {
    npx wrangler deploy --env $Environment
} finally {
    Pop-Location
}
