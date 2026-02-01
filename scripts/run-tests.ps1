<#
.SYNOPSIS
  Run Pester tests for dev-kit scripts. Uses Invoke-Pester if available, else runs a simple fallback.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$TestsDir = Join-Path $KitRoot "tests"

if (-not (Test-Path $TestsDir)) {
  Write-Host "tests/ not found; skipping unit tests." -ForegroundColor Yellow
  exit 0
}

# Prefer Pester 5+ (Invoke-Pester with -Path)
$pester = Get-Module -ListAvailable Pester | Where-Object { $_.Version.Major -ge 5 } | Select-Object -First 1
if (-not $pester) {
  $pester = Get-Module -ListAvailable Pester | Select-Object -First 1
}

if ($pester) {
  Import-Module Pester -MinimumVersion $pester.Version -ErrorAction SilentlyContinue
  if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
    Push-Location $KitRoot
    try {
      # Pester 5: New-PesterConfiguration; Pester 4: Invoke-Pester -Path
      if (Get-Command New-PesterConfiguration -ErrorAction SilentlyContinue) {
        $config = New-PesterConfiguration
        $config.Run.Path = $TestsDir
        $config.Run.Exit = $true
        $config.Output.Verbosity = "Normal"
        Invoke-Pester -Configuration $config
      } else {
        $result = Invoke-Pester -Path $TestsDir -PassThru
        # Pester 5: .Passed; Pester 3/4: .FailedCount -eq 0
        if ($result.PSObject.Properties.Name -contains "Passed") {
          if (-not $result.Passed) { exit 1 }
        } elseif ($result.FailedCount -gt 0) { exit 1 }
      }
      exit $LASTEXITCODE
    } finally {
      Pop-Location
    }
  }
}

# Fallback: run each .Tests.ps1 with simple assertion (exit 0 = pass)
Write-Host "Pester not found; running script exit-code checks." -ForegroundColor Cyan
$failed = $false
Get-ChildItem $TestsDir -Filter "*.Tests.ps1" | ForEach-Object {
  Write-Host "  Running $($_.Name)..."
  Push-Location $KitRoot
  try {
    & $_.FullName 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $failed = $true; Write-Host "    Failed (exit $LASTEXITCODE)" -ForegroundColor Red }
  } catch {
    $failed = $true
    Write-Host "    Error: $_" -ForegroundColor Red
  } finally {
    Pop-Location
  }
}
if ($failed) { exit 1 }
Write-Host "  All fallback checks passed." -ForegroundColor Green
exit 0
