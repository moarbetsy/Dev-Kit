<#
.SYNOPSIS
  Pester tests for scripts/bootstrap.ps1 (script exists and param block; full bootstrap not run due to admin/clone).
#>
$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$BootstrapPath = Join-Path $KitRoot "scripts\bootstrap.ps1"

Describe "Bootstrap" {
  It "scripts/bootstrap.ps1 exists" {
    Test-Path $BootstrapPath | Should Be $true
  }

  It "script has expected parameters (RepoUrl, DevRoot, Ref)" {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($BootstrapPath, [ref]$null, [ref]$null)
    $params = $ast.ParamBlock.Parameters.Name.VariablePath.UserPath
    $params -contains "RepoUrl" | Should Be $true
    $params -contains "DevRoot" | Should Be $true
    $params -contains "Ref" | Should Be $true
  }
}
