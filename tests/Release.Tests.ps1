<#
.SYNOPSIS
  Pester tests for scripts/release.ps1 (WhatIf and semver validation).
#>
$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ReleasePath = Join-Path $KitRoot "scripts\release.ps1"

Describe "Release" {
  It "WhatIf exits 0 and does not create zip" {
    Push-Location $KitRoot
    try {
      & $ReleasePath -ReleaseVersion "1.0.0" -WhatIf 2>$null
      $LASTEXITCODE | Should Be 0
      $zipPath = Join-Path $KitRoot "dist\dev-kit-0.0.0-whatif.zip"
      Test-Path $zipPath | Should Be $false
    } finally {
      Pop-Location
    }
  }

  It "fails with invalid ReleaseVersion when not WhatIf" {
    Push-Location $KitRoot
    try {
      & $ReleasePath -ReleaseVersion "invalid" 2>$null
      $LASTEXITCODE | Should Not Be 0
    } finally {
      Pop-Location
    }
  }

  It "WhatIf with valid version exits 0" {
    Push-Location $KitRoot
    try {
      & $ReleasePath -ReleaseVersion "2.0.0" -WhatIf 2>$null
      $LASTEXITCODE | Should Be 0
    } finally {
      Pop-Location
    }
  }
}
