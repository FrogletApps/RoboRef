<#
.SYNOPSIS
  Builds RoboRef Flutter app with automatic date-based version (YYYY.M.D) and Git commit count build number.
.PARAMETER Target
  The Flutter build target (e.g. apk, appbundle, web, windows, ipa). Default: apk.
.EXAMPLE
  .\scripts\build.ps1 apk
  .\scripts\build.ps1 appbundle
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

$appDir = Join-Path $PSScriptRoot "..\app"
Push-Location $appDir

try {
    flutter build $Target --build-name=$versionName --build-number=$buildNumber @ExtraArgs
} finally {
    Pop-Location
}
