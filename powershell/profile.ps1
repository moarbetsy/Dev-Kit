# --- Dev-kit profile ---

if (-not $env:DEVROOT -or $env:DEVROOT.Trim().Length -eq 0) {
  $env:DEVROOT = "D:\cursor_projects"
}
function cdev { Set-Location $env:DEVROOT }

if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (& starship init powershell)
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
  Set-Alias -Name ls -Value eza -Option AllScope
  function ll { eza -l --icons --git }
  function la { eza -la --icons --git }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
  Set-Alias -Name cat -Value bat -Option AllScope
  $env:GIT_PAGER = "bat -p"
}

if (Get-Command fd -ErrorAction SilentlyContinue) {
  Set-Alias -Name find -Value fd -Option AllScope
}

function fcd {
  if (-not (Get-Command fd -ErrorAction SilentlyContinue)) { return }
  if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { return }
  $dir = fd -t d . | fzf
  if ($dir) { Set-Location $dir }
}

function fe {
  if (-not (Get-Command fd -ErrorAction SilentlyContinue)) { return }
  if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { return }
  $file = fd -t f . | fzf
  if ($file) { cursor $file }
}

$env:EDITOR = "cursor"

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
