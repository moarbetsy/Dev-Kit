# Dev-kit (merged setup_script + Curated)

**Single entrypoint, rules pipeline, doctor/scan, governance template, CI, release.**  
Aims for a 100/100-style score: completeness, usability, maintainability, documentation, automation, simplicity, extensibility.

## How dev-kit relates to setup and curated

- **Setup** (parent dotfiles/setup_script) = bootstrap + setup only: get the machine and dotfiles ready. No single CLI, no doctor/scan/CI/release.
- **Curated** = the idea of one entrypoint for rules, doctor, scan, projects, governance, CI, release — but no machine/setup.
- **Dev-kit** = **Setup + Curated** in one repo: one entrypoint (`curated.ps1`) for bootstrap, setup, gen-rules, doctor, scan, new-project, governance, CI, and release. Use dev-kit when you want a single story for “machine + projects + quality.”

## Why dev-kit, rules, and install

**Better than setup/curated alone:** One entrypoint, project rules in repo (edit in `rules-src/`, run `gen-rules`), doctor/scan for CI, governance template, and release packaging. Setup only gives you machine + dotfiles; curated only gives you rules/doctor/scan; dev-kit gives you both plus a single CLI.

**Project rules are automatic.** Running `curated.ps1 gen-rules` writes `.cursor/rules/*.mdc` into the repo. Cursor reads those when you open the project — no paste step.

**Global rules are automatic too.** Per [Cursor docs](https://forum.cursor.com/t/why-cant-user-rules-be-set-in-the-system-user-directory-and-why-can-commands-be-set-in-c-users-user-cursor-commands/148764), global rules can live in `~/.cursor/rules/` (Mac/Linux) or `C:\Users\{user}\.cursor\rules\` (Windows). Setup writes `cursor/ai-rules.txt` into that directory as `dev-kit-global.md`, so they apply to all projects without pasting. Rules are also copied to the clipboard as a fallback.

**Simpler install.** The easiest path is: clone this repo, then run two commands (setup, then gen-rules). The long one-liner is for machines where you don't clone first (download bootstrap and run). See Quick start below.

## One-command entrypoint

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 help
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 setup
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 new MyApp -Type node
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 new -ProjectName MyApp -Type node -RunDoctor
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 gen-rules
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 doctor
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 scan
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 test
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 release -ReleaseVersion 1.0.0
```

## What’s included

| Area | Content |
|------|--------|
| **Bootstrap** | Long Paths, Developer Mode, optional Defender exclusions, clone, setup; no mandatory restart |
| **Setup** | PowerShell 7, Git, Starship, zoxide, eza, bat, fd, ripgrep, fzf, gh, Delugia Nerd Font, Bun, uv; profile, Git, SSH, Cursor rules |
| **Rules** | `rules-src/` → `curated.ps1 gen-rules` → `.cursor/rules/*.mdc` + `cursor/ai-rules.txt` |
| **Project** | `curated.ps1 new` (generic/node/python); optional `-FromGovernance`, `-RunDoctor`, GitHub, open in Cursor |
| **Governance** | `templates/governance/`: README, .gitignore, single CI workflow |
| **Doctor/Scan** | PowerShell doctor (lockfile, CI, README); scan outputs JSON for CI |
| **CI** | `.github/workflows/kit.yml`: gen-rules, doctor, scan |
| **Release** | `curated.ps1 release -ReleaseVersion <ver>` → `dist/dev-kit-<ver>.zip` |
| **Docs** | `docs/COMMANDS.md`, `docs/AGENT_PROTOCOL.md`, `docs/PATCH_RUNBOOK.md` |

## Quick start (fresh Windows)

**Simplest (clone first):** Clone this repo, then from the repo root:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 setup
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 gen-rules
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 test
```

Restart the terminal; global rules are already in `%USERPROFILE%\.cursor\rules\` (Cursor loads them automatically). Set Windows Terminal font to Delugia Nerd Font; run `gh auth login` if you use GitHub.

**No clone (one-liner):** For a fresh machine where you don’t clone first, use bootstrap. Set `$env:DEVKIT_OWNER` and `$env:DEVKIT_REPO`, then run the one-liner from `docs/COMMANDS.md` (Option A). Or replace `<OWNER>` and `<REPO>` in the command in `docs/COMMANDS.md` (Option B). Bootstrap downloads the script, runs as admin (Long Paths, Dev Mode), clones the repo, then runs setup.

## Layout

- **curated.ps1** — single CLI entrypoint  
- **scripts/** — bootstrap, setup, new-project, gen-rules, doctor, scan, release, self-test  
- **rules-src/** — source of truth for rules (edit here; gen-rules copies out)  
- **templates/governance/** — project template with CI contract  
- **docs/** — COMMANDS, AGENT_PROTOCOL, PATCH_RUNBOOK  
- **powershell/, starship/, git/, cursor/** — config (linked by setup)

## Configuration

- **Dev root**: `D:\cursor_projects` (override with `$env:DEVROOT` or setup params)  
- **Git**: MoarBetsy / MoarBetsy@gmail.com (override in bootstrap/setup)

## Compatibility

- **Windows** with winget; PowerShell 7 recommended.  
- Use quoted paths if they contain spaces; use process-level `-ExecutionPolicy Bypass` (no system change).
