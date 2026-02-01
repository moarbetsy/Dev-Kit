<#
.SYNOPSIS
  Pester tests for scripts/gen-rules.ps1 — ensures gen-rules produces expected output.
#>
$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$GenRulesPath = Join-Path $KitRoot "scripts\gen-rules.ps1"
$RulesSrc = Join-Path $KitRoot "rules-src"
$CursorRulesDir = Join-Path $KitRoot ".cursor\rules"
$CursorAiRules = Join-Path $KitRoot "cursor\ai-rules.txt"

Describe "GenRules" {
  It "produces .cursor/rules/*.mdc when rules-src has .md files" {
    if (-not (Test-Path $RulesSrc)) { Set-ItResult -Inconclusive -Because "rules-src/ missing" }
    Push-Location $KitRoot
    try {
      & $GenRulesPath 2>$null
      (Test-Path $CursorRulesDir) | Should Be $true
      $mdcCount = @(Get-ChildItem $CursorRulesDir -Filter "*.mdc" -ErrorAction SilentlyContinue).Count
      $mdcCount | Should BeGreaterThan 0
    } finally {
      Pop-Location
    }
  }

  It "produces cursor/ai-rules.txt" {
    if (-not (Test-Path $RulesSrc)) { Set-ItResult -Inconclusive -Because "rules-src/ missing" }
    Push-Location $KitRoot
    try {
      & $GenRulesPath 2>$null
      Test-Path $CursorAiRules | Should Be $true
      (Get-Item $CursorAiRules).Length | Should BeGreaterThan 0
    } finally {
      Pop-Location
    }
  }
}
