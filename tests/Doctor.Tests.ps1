<#
.SYNOPSIS
  Pester tests for scripts/doctor.ps1
#>
$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$DoctorPath = Join-Path $KitRoot "scripts\doctor.ps1"

Describe "Doctor" {
  It "passes when run in dev-kit root (after gen-rules)" {
    Push-Location $KitRoot
    try {
      & $DoctorPath 2>$null
      $LASTEXITCODE | Should Be 0
    } finally {
      Pop-Location
    }
  }

  It "governance-only passes when run from dev-kit" {
    Push-Location $KitRoot
    try {
      & $DoctorPath -GovernanceOnly 2>$null
      $LASTEXITCODE | Should Be 0
    } finally {
      Pop-Location
    }
  }

  It "fails when README.md is missing" {
    $tempDir = Join-Path $env:TEMP "doctor-test-$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    try {
      Push-Location $tempDir
      & $DoctorPath 2>$null
      $LASTEXITCODE | Should Not Be 0
    } finally {
      Pop-Location
      Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}
