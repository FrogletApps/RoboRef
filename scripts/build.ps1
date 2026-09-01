<#
.SYNOPSIS
  Builds RoboRef Flutter app and/or Sync Server with automatic date-based version (YYYY.M.D) and Git commit count build number.
.PARAMETER Target
  The build target (e.g. apk, server, all, appbundle, web, windows, ipa). Default: apk.
.EXAMPLE
  .\scripts\build.ps1 apk
  .\scripts\build.ps1 server
  .\scripts\build.ps1 all
  .\scripts\build.ps1 web
#>
param (
    [string]$Target = "apk",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

# Get current date formatted as YYYY.M.D (e.g., 2026.8.23)
$today = Get-Date
$versionName = "$($today.Year).$($today.Month).$($today.Day)"

# Get commit count from git
try {
    $buildNumber = (git rev-list --count HEAD).Trim()
} catch {
    $buildNumber = "1"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Building RoboRef ($Target)" -ForegroundColor Cyan
Write-Host " Version Name: $versionName" -ForegroundColor Yellow
Write-Host " Build Number: $buildNumber" -ForegroundColor Yellow
Write-Host " Full Version: $versionName+$buildNumber" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

function Build-Server {
    Write-Host "`n>>> Building & Typechecking Server..." -ForegroundColor Cyan
    $serverDir = Join-Path $PSScriptRoot "..\server"
    Push-Location $serverDir
    try {
        if (-not (Test-Path (Join-Path $serverDir "node_modules"))) {
            Write-Host "Installing server dependencies (npm install)..." -ForegroundColor Yellow
            npm install
            if ($LASTEXITCODE -ne 0) { throw "npm install failed in server directory" }
        }
        Write-Host "Running server typecheck..." -ForegroundColor Gray
        npm run typecheck
        if ($LASTEXITCODE -ne 0) { throw "Server typecheck failed" }

        Write-Host "Compiling server (tsc)..." -ForegroundColor Gray
        npm run build:node
        if ($LASTEXITCODE -ne 0) { throw "Server build failed" }

        Write-Host ">>> Server build completed successfully." -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Build-Flutter([string]$flutterTarget) {
    Write-Host "`n>>> Building Flutter Client ($flutterTarget)..." -ForegroundColor Cyan
    $appDir = Join-Path $PSScriptRoot "..\app"
    Push-Location $appDir
    try {
        flutter build $flutterTarget --build-name=$versionName --build-number=$buildNumber @ExtraArgs
        if ($LASTEXITCODE -ne 0) { throw "Flutter build failed for target '$flutterTarget'" }
        Write-Host ">>> Flutter client ($flutterTarget) build completed successfully." -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

switch ($Target.ToLower()) {
    "server" {
        Build-Server
    }
    "all" {
        Build-Server
        Build-Flutter "apk"
    }
    default {
        Build-Flutter $Target
    }
}
