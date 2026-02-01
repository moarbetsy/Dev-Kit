# Copy-paste commands

## Entrypoint (from dev-kit root)
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 <command> [args]
```

## Commands
| Command | Description |
|---------|-------------|
| `help` | Show command list (default) |
| `setup` | Full setup: apps, lang tools, PowerShell, Git, SSH, Cursor rules |
| `bootstrap` | Fresh machine: admin (Long Paths, Dev Mode), clone, setup; optional `-IncludeDefenderExclusions` |
| `new -ProjectName <Name> [-Type node\|python] ...` or `new <Name> -Type node` | Create project |
| `gen-rules` | Regenerate `.cursor/rules/*.mdc` and `cursor/ai-rules.txt` from `rules-src/` |
| `doctor` | Project doctor: lockfile, CI, README, rules (dev-kit repo) |
| `governance` | Governance template doctor |
| `scan` | JSON diagnostics (for CI) |
| `test` | gen-rules + doctor + scan + rules check |
| `release -ReleaseVersion <ver>` | Build `dist/dev-kit-<ver>.zip` (semver required). Optional `-WhatIf` to preview. |

---

## First time (clone then setup and verify)
Run once after cloning dev-kit:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 setup
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 gen-rules
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 test
```
Then restart your terminal; global rules are in `%USERPROFILE%\.cursor\rules\` (Cursor loads them automatically). Set Windows Terminal font to Delugia Nerd Font; run `gh auth login` if needed.

---

## New project (create and optionally run doctor)
```powershell
# Create a node project named MyApp and run doctor
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 new MyApp -Type node -RunDoctor

# Or with -ProjectName
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 new -ProjectName MyApp -Type node -RunDoctor
```

---

## One-liner bootstrap (new machine)
**Option A — env vars (no edit):** set `DEVKIT_OWNER` and `DEVKIT_REPO`, then:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& { $f = Join-Path $env:TEMP 'bootstrap.ps1'; Invoke-WebRequest -Uri \"https://raw.githubusercontent.com/$env:DEVKIT_OWNER/$env:DEVKIT_REPO/main/scripts/bootstrap.ps1\" -OutFile $f -UseBasicParsing; & pwsh -NoProfile -ExecutionPolicy Bypass -File $f -RepoUrl \"https://github.com/$env:DEVKIT_OWNER/$env:DEVKIT_REPO.git\" -Ref main }"
```

**Option B — replace `<OWNER>` and `<REPO>` with your GitHub org/repo:**
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -Command "& { $f = Join-Path $env:TEMP 'bootstrap.ps1'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/<OWNER>/<REPO>/main/scripts/bootstrap.ps1' -OutFile $f -UseBasicParsing; & pwsh -NoProfile -ExecutionPolicy Bypass -File $f -RepoUrl 'https://github.com/<OWNER>/<REPO>' -Ref main }"
```

## After bootstrap
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\dev-kit\curated.ps1" test
pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\dev-kit\curated.ps1" new -ProjectName MyApp -Type node -RunDoctor
```
