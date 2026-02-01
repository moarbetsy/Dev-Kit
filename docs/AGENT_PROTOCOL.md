# Agent protocol

Short contract for AI/agent use of this repo.

## Rules
- **Single source of rules**: Edit in `rules-src/`; run `curated.ps1 gen-rules` to update `.cursor/rules/` and `cursor/ai-rules.txt`.
- **One CI entrypoint**: Use `.github/workflows/ci.yml` (or single workflow) for lint/test/build; add jobs there instead of many workflow files.
- **Lockfile law**: Node projects must have `bun.lockb` or `package-lock.json` or `yarn.lock`; Python projects should have lockfiles where applicable.

## Commands agents can run
- `curated.ps1 gen-rules` — after editing `rules-src/`.
- `curated.ps1 doctor` — to validate repo/project.
- `curated.ps1 scan` — to get JSON diagnostics (CI).
- `curated.ps1 test` — full check (gen-rules + doctor + scan).

## Docs
- `docs/COMMANDS.md` — copy-paste commands.
- `docs/PATCH_RUNBOOK.md` — how to apply changes safely.
