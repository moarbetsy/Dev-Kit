<#
.SYNOPSIS
  Single entrypoint for the dev-kit: setup, new project, doctor, scan, gen-rules, test, release.
.DESCRIPTION
  Merged Cursor-first dev environment: bootstrap, tool install, rules pipeline, project scaffold,
  governance template, doctor/scan for CI, and release packaging.
.EXAMPLE
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 help
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 setup
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 new MyApp -Type node -RunDoctor
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 scan
#>
param(
  [Parameter(Position = 0)]
  [ValidateSet("help", "setup", "bootstrap", "new", "gen-rules", "doctor", "governance", "scan", "test", "release")]
  [string]$Command = "help",

  # Pass-through for: new (use -ProjectName to avoid common parameter -Name)
  [string]$ProjectName,
  [ValidateSet("generic", "node", "python")]
  [string]$Type = "generic",
  [string]$DevRoot = "D:\cursor_projects",
  [switch]$NoGitHub,
  [switch]$NoOpen,
  [switch]$RunDoctor,
  [switch]$FromGovernance,
  # Pass-through for: release
  [string]$ReleaseVersion,
  [switch]$WhatIf,
  # Pass-through for: bootstrap
  [string]$RepoUrl,
  [string]$Ref = "main",
  [switch]$IncludeDefenderExclusions,
  [string]$NewProjectName,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Remaining
)
$SubArgs = @($Remaining)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsDir = Join-Path $ScriptDir "scripts"

function Show-Help {
  Write-Host "dev-kit (curated.ps1) — single entrypoint"
  Write-Host ""
  Write-Host "  help              Show this list (default)"
  Write-Host "  setup             Run full setup (apps, lang tools, PowerShell, Git, SSH, Cursor rules)"
  Write-Host "  bootstrap         Fresh-machine bootstrap (admin: Long Paths, Dev Mode, clone, setup); optional -IncludeDefenderExclusions"
  Write-Host "  new               Create project: -ProjectName <Name> [-Type generic|node|python] [-RunDoctor] [-NoGitHub] [-NoOpen]"
  Write-Host "                    Or: new <Name> -Type node (name as first arg)"
  Write-Host "  gen-rules         Regenerate .cursor/rules/*.mdc and cursor/ai-rules.txt from rules-src/"
  Write-Host "  doctor            Run project/repo doctor (lockfile, CI entrypoint, structure)"
  Write-Host "  governance        Run governance template doctor (templates/governance)"
  Write-Host "  scan              Run diagnostics, output JSON (for CI)"
  Write-Host "  test              Run gen-rules + doctor + scan + rules check"
  Write-Host "  release           Build release zip: -ReleaseVersion <version>"
  Write-Host ""
  Write-Host "Examples (defaults: DevRoot=D:\cursor_projects, Type=generic):"
  Write-Host "  .\curated.ps1 setup"
  Write-Host "  .\curated.ps1 new MyApp -Type node"
  Write-Host "  .\curated.ps1 new -ProjectName MyApp -Type python -RunDoctor"
  Write-Host "  .\curated.ps1 release -ReleaseVersion 1.0.0"
  Write-Host "  .\curated.ps1 bootstrap -RepoUrl https://github.com/MyOrg/my-kit.git"
  Write-Host ""
  Write-Host "Entrypoint: pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 <command> [args]"
  Write-Host "Docs: docs\COMMANDS.md, docs\AGENT_PROTOCOL.md, docs\EXTENDING.md"
}

function Invoke-PwshFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string[]]$Args = @()
  )
  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
  if ($pwsh) {
    & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $Path @Args
  } else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Path @Args
  }
}

# Validate required args and show friendly usage
function Require-ReleaseVersion {
  if (-not $PSBoundParameters.ContainsKey("ReleaseVersion") -or [string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    Write-Host "Usage: curated.ps1 release -ReleaseVersion <version>" -ForegroundColor Yellow
    Write-Host "Example: curated.ps1 release -ReleaseVersion 1.0.0" -ForegroundColor Gray
    exit 1
  }
}

# Normalize new: first positional arg (no leading -) = project name
# Script's $PSBoundParameters is not visible inside this function; pass ProjectName and SubArgs explicitly.
function Get-NewProjectArgs {
  param([string]$ProjectNameValue, [string[]]$SubArgsValue)
  if (-not [string]::IsNullOrWhiteSpace($ProjectNameValue)) {
    return @("-Name", $ProjectNameValue), $SubArgsValue
  }
  if ($SubArgsValue -and $SubArgsValue.Count -gt 0 -and $SubArgsValue[0] -notlike '-*') {
    $name = $SubArgsValue[0]
    $rest = if ($SubArgsValue.Count -gt 1) { $SubArgsValue[1..($SubArgsValue.Count - 1)] } else { @() }
    return @("-Name", $name), $rest
  }
  return $null, $SubArgsValue
}

switch ($Command) {
  "help" {
    Show-Help
    exit 0
  }
  "setup" {
    $setupArgs = @("-All")
    if ($SubArgs -and $SubArgs.Count -gt 0) { $setupArgs += $SubArgs }
    Invoke-PwshFile (Join-Path $ScriptsDir "setup.ps1") $setupArgs
    exit 0
  }
  "bootstrap" {
    $bootArgs = @()
    if ($PSBoundParameters.ContainsKey("RepoUrl")) { $bootArgs += "-RepoUrl", $RepoUrl }
    if ($PSBoundParameters.ContainsKey("Ref")) { $bootArgs += "-Ref", $Ref }
    if ($PSBoundParameters.ContainsKey("DevRoot")) { $bootArgs += "-DevRoot", $DevRoot }
    if ($IncludeDefenderExclusions) { $bootArgs += "-IncludeDefenderExclusions" }
    if ($PSBoundParameters.ContainsKey("NewProjectName")) { $bootArgs += "-NewProjectName", $NewProjectName }
    if ($bootArgs.Count -eq 0) { $bootArgs = $SubArgs }
    Invoke-PwshFile (Join-Path $ScriptsDir "bootstrap.ps1") $bootArgs
    exit 0
  }
  "new" {
    $newArgs, $rest = Get-NewProjectArgs -ProjectNameValue $ProjectName -SubArgsValue $SubArgs
    if (-not $newArgs) {
      Write-Host "Usage: curated.ps1 new -ProjectName <Name> [-Type generic|node|python] [-RunDoctor] [-NoGitHub] [-NoOpen]" -ForegroundColor Yellow
      Write-Host "   or: curated.ps1 new <Name> -Type node" -ForegroundColor Yellow
      Write-Host "Example: curated.ps1 new MyApp -Type node -RunDoctor" -ForegroundColor Gray
      exit 1
    }
    if ($PSBoundParameters.ContainsKey("Type")) { $newArgs += "-Type", $Type }
    if ($PSBoundParameters.ContainsKey("DevRoot")) { $newArgs += "-DevRoot", $DevRoot }
    if ($NoGitHub) { $newArgs += "-NoGitHub" }
    if ($NoOpen) { $newArgs += "-NoOpen" }
    if ($RunDoctor) { $newArgs += "-RunDoctor" }
    if ($FromGovernance) { $newArgs += "-FromGovernance" }
    $allArgs = @()
    $allArgs += $newArgs
    $allArgs += @($rest | Where-Object { $null -ne $_ -and $_ -ne '' })
    Invoke-PwshFile (Join-Path $ScriptsDir "new-project.ps1") $allArgs
    exit 0
  }
  "gen-rules" {
    Invoke-PwshFile (Join-Path $ScriptsDir "gen-rules.ps1")
    exit 0
  }
  "doctor" {
    Invoke-PwshFile (Join-Path $ScriptsDir "doctor.ps1") $SubArgs
    exit 0
  }
  "governance" {
    Invoke-PwshFile (Join-Path $ScriptsDir "doctor.ps1") @("-GovernanceOnly")
    exit 0
  }
  "scan" {
    Invoke-PwshFile (Join-Path $ScriptsDir "scan.ps1")
    exit 0
  }
  "test" {
    Invoke-PwshFile (Join-Path $ScriptsDir "self-test.ps1")
    exit 0
  }
  "release" {
    Require-ReleaseVersion
    $relArgs = @("-ReleaseVersion", $ReleaseVersion)
    if ($WhatIf) { $relArgs += "-WhatIf" }
    $allArgs = @()
    $allArgs += $relArgs
    $allArgs += $SubArgs
    Invoke-PwshFile (Join-Path $ScriptsDir "release.ps1") $allArgs
    exit 0
  }
  default {
    Show-Help
    exit 0
  }
}

# To add a new command: add to ValidateSet above, then add a branch here, e.g.:
#   "mycommand" { & (Join-Path $ScriptsDir "mycommand.ps1") @SubArgs; exit 0 }
