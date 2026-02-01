<#
.SYNOPSIS
  Pester tests for scripts/new-project.ps1 (create in temp dir, existing dir fails).
#>
$KitRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$NewProjectPath = Join-Path $KitRoot "scripts\new-project.ps1"

Describe "NewProject" {
  It "creates a generic project in temp DevRoot with README and .git" {
    $testRoot = Join-Path $env:TEMP "new-project-test-$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
    try {
      Push-Location $KitRoot
      try {
        & $NewProjectPath -Name "TestProj" -Type generic -DevRoot $testRoot -NoGitHub -NoOpen 2>$null
        $LASTEXITCODE | Should Be 0
      } finally {
        Pop-Location
      }
      $projectDir = Join-Path $testRoot "TestProj"
      Test-Path $projectDir | Should Be $true
      Test-Path (Join-Path $projectDir "README.md") | Should Be $true
      Test-Path (Join-Path $projectDir ".git") | Should Be $true
    } finally {
      Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  It "fails when project directory already exists" {
    $testRoot = Join-Path $env:TEMP "new-project-test-$(Get-Random)"
    $existingProj = Join-Path $testRoot "ExistingProj"
    New-Item -ItemType Directory -Force -Path $existingProj | Out-Null
    try {
      $pwsh = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }
      & $pwsh -NoProfile -ExecutionPolicy Bypass -File $NewProjectPath -Name "ExistingProj" -Type generic -DevRoot $testRoot -NoGitHub -NoOpen 2>$null
      $LASTEXITCODE | Should Not Be 0
    } finally {
      Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}
