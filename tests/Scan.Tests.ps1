<#
.SYNOPSIS
  Pester tests for scripts/scan.ps1
#>
$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ScanPath = Join-Path $KitRoot "scripts\scan.ps1"

Describe "Scan" {
  It "outputs valid JSON and exits 0 in dev-kit root" {
    Push-Location $KitRoot
    try {
      $out = & $ScanPath 2>&1 | Out-String
      $LASTEXITCODE | Should Be 0
      $json = $out | ConvertFrom-Json
      $json | Should Not BeNullOrEmpty
      $json.checks | Should Not BeNullOrEmpty
      ($json.PSObject.Properties.Name -contains "ok") | Should Be $true
    } finally {
      Pop-Location
    }
  }

  It "report contains doctor_ok and has_rules when run in dev-kit" {
    Push-Location $KitRoot
    try {
      $out = & $ScanPath 2>&1 | Out-String
      $json = $out | ConvertFrom-Json
      ($json.PSObject.Properties.Name -contains "doctor_ok") | Should Be $true
      ($json.PSObject.Properties.Name -contains "has_rules") | Should Be $true
      ($json.PSObject.Properties.Name -contains "has_governance") | Should Be $true
    } finally {
      Pop-Location
    }
  }
}
