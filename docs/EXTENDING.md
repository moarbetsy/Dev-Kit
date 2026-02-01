# Extending dev-kit

How to add a new command, project type, doctor check, or governance template file.

---

## Add a new command to curated.ps1

1. **Add the command to the validated set**  
   In `curated.ps1`, find the param block and add your command name to `ValidateSet`:
   ```powershell
   [ValidateSet("help", "setup", "bootstrap", "new", "gen-rules", "doctor", "governance", "scan", "test", "release", "mycommand")]
   ```

2. **Add a switch branch**  
   In the same file, add a branch in the `switch ($Command)` block:
   ```powershell
   "mycommand" {
     & (Join-Path $ScriptsDir "mycommand.ps1") @SubArgs
     exit 0
   }
   ```

3. **Create the script**  
   Add `scripts/mycommand.ps1` and implement your logic. Use `$SubArgs` for any extra arguments passed after the command name.

4. **Update help**  
   In `Show-Help` in `curated.ps1`, add a line for `mycommand` and optionally an example at the bottom of the help block.

5. **Document**  
   Add the command to `docs/COMMANDS.md` in the Commands table.

---

## Add a new project type to new-project.ps1

1. **Add the type to the validated set**  
   In `new-project.ps1`, add your type (e.g. `rust`) to:
   ```powershell
   [ValidateSet("generic", "node", "python", "rust")]
   [string]$Type = "generic",
   ```

2. **Add a branch in the type switch**  
   Find the `switch ($Type)` block (or the section that creates type-specific files). Add a case for your type, e.g.:
   - Create a `.gitignore` snippet for the type.
   - Optionally run a tool (e.g. `cargo init`) or create starter files.

3. **Update curated.ps1**  
   In `curated.ps1`, add `rust` (or your type) to the `[ValidateSet("generic", "node", "python")]` for the `$Type` parameter so users can pass `-Type rust`. Keep the type in sync in **both** `curated.ps1` and `new-project.ps1`.

4. **Document**  
   Update `docs/COMMANDS.md` and `README.md` to mention the new type.

---

## Add a doctor check

1. **Open doctor.ps1**  
   `scripts/doctor.ps1` runs repo and (optionally) dev-kit–specific checks.

2. **Choose where to add the check**  
   - **Any repo:** add logic in the `if (-not $GovernanceOnly)` block (e.g. check for a lockfile, README, CI).
   - **Dev-kit repo only:** add logic inside `if ($isKitRepo -and -not $SkipRulesCheck)` (e.g. require a certain file or folder).

3. **Append to `$issues` on failure**  
   Use `[void]$issues.Add("Clear message (and how to fix)")` when the check fails.

4. **Optional: add a scan field**  
   In `scripts/scan.ps1`, add a field to the `$report` object and a `$report.checks += @{ name = "my_check"; ok = $true/$false }` so CI can consume it.

---

## Add a file or workflow to the governance template

The governance template is `templates/governance/`. Projects created with `curated.ps1 new -FromGovernance` copy this folder.

1. **Add the file**  
   Create or edit files under `templates/governance/`, e.g.:
   - `templates/governance/README.md` — project README.
   - `templates/governance/.gitignore` — project gitignore.
   - `templates/governance/.github/workflows/ci.yml` — CI contract (doctor expects at least one workflow under `.github/workflows/`).

2. **Keep the contract**  
   Doctor’s governance check expects:
   - `templates/governance/README.md`
   - `templates/governance/.gitignore`
   - `templates/governance/.github/workflows/` (at least one workflow)

   If you add a new required file, add a check for it in `scripts/doctor.ps1` in the `if ($GovernanceOnly)` block.

   **Note:** Dev-kit’s own CI (`.github/workflows/kit.yml`) runs on `windows-latest`; the governance template’s `ci.yml` uses `ubuntu-latest`. When copying the template into a project, be aware of the runner OS if you target a specific platform.

3. **Document**  
   In `README.md` or `docs/COMMANDS.md`, note that `-FromGovernance` uses `templates/governance/` and what it includes.

---

## Running doctor/scan after changes

After changing doctor, scan, or the governance template, run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 test
```

Before release, run the full test suite (including unit tests if you added Pester):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\curated.ps1 test
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
```

See `docs/PATCH_RUNBOOK.md` and `docs/AGENT_PROTOCOL.md` for more workflow details.
