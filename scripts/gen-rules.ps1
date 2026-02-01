<#
.SYNOPSIS
  Regenerate .cursor/rules/*.mdc and cursor/ai-rules.txt from rules-src/.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Info($m) { Write-Host "  $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  $m" -ForegroundColor Green }

$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$RulesSrc = Join-Path $KitRoot "rules-src"
$CursorRulesDir = Join-Path $KitRoot ".cursor\rules"
$CursorAiRules = Join-Path $KitRoot "cursor\ai-rules.txt"

if (-not (Test-Path $RulesSrc)) {
  New-Item -ItemType Directory -Force -Path $RulesSrc | Out-Null
  @"
# Repo-wide rules (source of truth)
# Edit here; gen-rules copies to .cursor/rules/*.mdc and cursor/ai-rules.txt

## General
- Write clean, maintainable code.
- Follow language-specific best practices.
- Prefer explicit over implicit; handle errors gracefully.

## Code style
- Meaningful names; small focused functions; early returns; composition over inheritance.

## Testing
- Tests for critical paths; descriptive names; edge cases.

## Documentation
- Document public APIs; keep README up to date; document non-obvious decisions.
"@ | Out-File -Encoding utf8 (Join-Path $RulesSrc "global.md")
  Ok "Created rules-src/global.md (default). Run gen-rules again."
  exit 0
}

New-Item -ItemType Directory -Force -Path $CursorRulesDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $CursorAiRules) | Out-Null

$combined = [System.Collections.ArrayList]::new()
Get-ChildItem $RulesSrc -Filter "*.md" | ForEach-Object {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  $mdcPath = Join-Path $CursorRulesDir "$name.mdc"
  $content = Get-Content $_.FullName -Raw
  [void]$combined.Add($content)
  Set-Content -Path $mdcPath -Value $content -Encoding utf8 -NoNewline
  Ok "Generated .cursor/rules/$name.mdc"
}

if (Test-Path (Join-Path $RulesSrc "ai-rules.txt")) {
  Copy-Item (Join-Path $RulesSrc "ai-rules.txt") $CursorAiRules -Force
  Ok "Copied cursor/ai-rules.txt"
} else {
  $defaultRules = @"
# Cursor AI Rules — paste into Cursor → Settings → Rules for AI

## General
- Write clean, maintainable code; follow best practices; handle errors gracefully.

## Code style
- Meaningful names; small functions; early returns; composition over inheritance.

## Testing
- Tests for critical functionality; descriptive names; edge cases.

## Documentation
- Document public APIs; keep README updated; document non-obvious decisions.
"@
  Set-Content -Path $CursorAiRules -Value $defaultRules -Encoding utf8
  Ok "Generated cursor/ai-rules.txt (default)"
}

Ok "gen-rules done."
