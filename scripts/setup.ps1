param(
  [string]$DevRoot = "D:\cursor_projects",
  [string]$GitUserName = "MoarBetsy",
  [string]$GitUserEmail = "MoarBetsy@gmail.com",
  [string]$GitHubUser = "MoarBetsy",

  [switch]$All = $true,
  [switch]$InstallApps,
  [switch]$InstallLangTools,
  [switch]$ConfigurePowerShell,
  [switch]$ConfigureGit,
  [switch]$ConfigureSSH,
  [switch]$PrepareCursorRules
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Info($m)  { Write-Host "  $m" -ForegroundColor Cyan }
function Ok($m)    { Write-Host "  $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  $m" -ForegroundColor Yellow }

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ProfileSource = Join-Path $RepoRoot "powershell\profile.ps1"
$StarshipSource = Join-Path $RepoRoot "starship\starship.toml"
$GitignoreSource = Join-Path $RepoRoot "git\gitignore_global"
$CursorRulesSource = Join-Path $RepoRoot "cursor\ai-rules.txt"

function Assert-Command($name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}
function Ensure-Dir($path) {
  New-Item -ItemType Directory -Force -Path $path | Out-Null
}
function Backup-IfExists($path) {
  if (Test-Path $path) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bak = "$path.bak.$stamp"
    Copy-Item $path $bak -Force
    Warn "Backed up: $path -> $bak"
  }
}
function Link-File($source, $dest) {
  Ensure-Dir (Split-Path $dest)
  if (Test-Path $dest) {
    try {
      $item = Get-Item $dest -Force
      if ($item.LinkType -and $item.Target -eq $source) {
        Ok "Link already set: $dest -> $source"
        return
      }
    } catch {}
    Backup-IfExists $dest
    Remove-Item $dest -Force
  }
  try {
    New-Item -ItemType SymbolicLink -Path $dest -Target $source | Out-Null
    Ok "Linked: $dest -> $source"
  } catch {
    Warn "Symlink failed. Falling back to copy."
    Copy-Item $source $dest -Force
    Ok "Copied: $dest"
  }
}
function Winget-Install($id) {
  if (-not (Assert-Command winget)) { throw "winget not found. Install 'App Installer' from Microsoft Store." }
  $isInstalled = $false
  try { $null = winget list --id $id -e; if ($LASTEXITCODE -eq 0) { $isInstalled = $true } } catch {}
  if ($isInstalled) { Ok "$id already installed"; return }
  Info "Installing: $id"
  winget install -e --id $id --silent --disable-interactivity --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) {
    Warn "Silent failed for $id; retrying interactive."
    winget install -e --id $id --accept-source-agreements --accept-package-agreements
  }
  Ok "Installed: $id"
}
function Ensure-DevRoot {
  Info "Ensuring Dev root: $DevRoot"
  Ensure-Dir $DevRoot
  Ok "Dev root ready"
}
function Ensure-PwshPath {
  $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
  if (-not $pwsh) {
    $candidate = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"
    if (Test-Path $candidate) { $pwsh = $candidate }
  }
  if (-not $pwsh) { throw "PowerShell 7 (pwsh) not found. Install Microsoft.PowerShell and re-run." }
  return $pwsh
}

function Install-Apps {
  Info "Phase: Install Apps (winget)"
  $packages = @(
    "Microsoft.PowerShell", "Git.Git", "Starship.Starship", "ajeetdsouza.zoxide",
    "eza-community.eza", "sharkdp.bat", "BurntSushi.ripgrep.MSVC", "junegunn.fzf",
    "sharkdp.fd", "GitHub.cli", "RyanLMcIntyre.DelugiaNerdFont"
  )
  foreach ($p in $packages) { Winget-Install $p }
}
function Install-LangTools {
  Info "Phase: Install Bun + uv"
  $pwsh = Ensure-PwshPath
  if (-not (Assert-Command bun)) {
    Info "Installing Bun..."
    & $pwsh -NoProfile -c "irm bun.sh/install.ps1 | iex"
    Ok "Bun installed"
  } else { Ok "Bun already installed" }
  if (-not (Assert-Command uv)) {
    Info "Installing uv..."
    & $pwsh -NoProfile -c "irm https://astral.sh/uv/install.ps1 | iex"
    Ok "uv installed"
  } else { Ok "uv already installed" }
}
function Configure-PowerShell {
  Info "Phase: Configure PowerShell + Starship + DEVROOT"
  try {
    [Environment]::SetEnvironmentVariable("DEVROOT", $DevRoot, "User")
    $env:DEVROOT = $DevRoot
    Ok "Set DEVROOT: $DevRoot"
  } catch { Warn "Could not persist DEVROOT." }
  $ProfileDest = $PROFILE
  Link-File $ProfileSource $ProfileDest
  $ConfigDir = Join-Path $HOME ".config"
  Ensure-Dir $ConfigDir
  Link-File $StarshipSource (Join-Path $ConfigDir "starship.toml")
  Ok "PowerShell + Starship configured (restart terminal)"
}
function Configure-Git {
  Info "Phase: Configure Git"
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  $gitCmd = $null
  if (Assert-Command git) { $gitCmd = "git" }
  else {
    $pf = $env:ProgramFiles
    $pf86 = ${env:ProgramFiles(x86)}
    $candidates = @(
      (Join-Path $pf "Git\cmd\git.exe"),
      (Join-Path $pf86 "Git\cmd\git.exe")
    )
    foreach ($path in $candidates) {
      if (Test-Path $path) { $gitCmd = $path; $env:Path = "$(Split-Path (Split-Path $path));$env:Path"; break }
    }
  }
  if (-not $gitCmd) { throw "git not found. Install Git.Git via winget, then restart terminal." }
  & $gitCmd config --global init.defaultBranch main
  & $gitCmd config --global core.autocrlf false
  & $gitCmd config --global core.eol lf
  & $gitCmd config --global pull.rebase true
  & $gitCmd config --global rebase.autoStash true
  & $gitCmd config --global fetch.prune true
  & $gitCmd config --global diff.algorithm histogram
  & $gitCmd config --global merge.conflictstyle zdiff3
  & $gitCmd config --global user.name $GitUserName
  & $gitCmd config --global user.email $GitUserEmail
  & $gitCmd config --global github.user $GitHubUser
  $GitignoreDest = Join-Path $HOME ".gitignore_global"
  Link-File $GitignoreSource $GitignoreDest
  & $gitCmd config --global core.excludesfile $GitignoreDest
  Ok "Git configured for $GitUserName"
}
function Ensure-OpenSSHClientIfMissing {
  if (Assert-Command ssh-keygen) { return $true }
  try { Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 | Out-Null } catch { return $false }
  return (Assert-Command ssh-keygen)
}
function Configure-SSH {
  Info "Phase: Configure SSH"
  if (-not (Ensure-OpenSSHClientIfMissing)) { Warn "Skipping SSH: OpenSSH Client not available."; return }
  $sshDir = Join-Path $env:USERPROFILE ".ssh"
  Ensure-Dir $sshDir
  $keyPath = Join-Path $sshDir "id_ed25519"
  if (-not (Test-Path $keyPath)) {
    Info "Generating SSH key (ed25519)..."
    ssh-keygen -t ed25519 -C $GitUserEmail -f $keyPath -N "" -q
    Ok "SSH key generated"
  } else { Ok "SSH key exists" }
  try {
    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    ssh-add $keyPath | Out-Null
    Ok "Key in ssh-agent"
  } catch { Warn "ssh-agent setup failed." }
  if (Test-Path "$keyPath.pub") { Get-Content "$keyPath.pub" | Set-Clipboard; Ok "Public key copied to clipboard" }
}
function Prepare-CursorRules {
  Info "Phase: Prepare Cursor AI rules"
  if (-not (Test-Path $CursorRulesSource)) {
    Warn "Cursor rules not found. Run 'curated.ps1 gen-rules' first."
    return
  }
  # Cursor docs: global rules in files at ~/.cursor/rules/ (Mac/Linux) or C:\Users\{user}\.cursor\rules\ (Windows)
  $userRulesDir = Join-Path $env:USERPROFILE ".cursor\rules"
  Ensure-Dir $userRulesDir
  $userRulesFile = Join-Path $userRulesDir "dev-kit-global.md"
  $content = Get-Content $CursorRulesSource -Raw
  Set-Content -Path $userRulesFile -Value $content -Encoding utf8 -NoNewline
  Ok "Cursor global rules written to $userRulesFile (apply to all projects)"
  Get-Content $CursorRulesSource -Raw | Set-Clipboard
  Ok "Rules also copied to clipboard (paste into Cursor → Settings → Rules if needed)"
}

if ($All) {
  $InstallApps = $true
  $InstallLangTools = $true
  $ConfigurePowerShell = $true
  $ConfigureGit = $true
  $ConfigureSSH = $true
  $PrepareCursorRules = $true
}

Info "Repo root: $RepoRoot"
Ensure-DevRoot
if ($InstallApps)         { Install-Apps }
if ($InstallLangTools)    { Install-LangTools }
if ($ConfigurePowerShell) { Configure-PowerShell }
if ($ConfigureGit)        { Configure-Git }
if ($ConfigureSSH)        { Configure-SSH }
if ($PrepareCursorRules)  { Prepare-CursorRules }

Ok "Done. Restart terminal to load profile. Dev root: $DevRoot"
