# Patch runbook

How to apply changes to the dev-kit or to a project created from it.

## Before editing rules
1. Edit files in `rules-src/` (e.g. `global.md`, `ai-rules.txt`).
2. Run `curated.ps1 gen-rules` to update `.cursor/rules/` and `cursor/ai-rules.txt`.
3. Commit both `rules-src/` and generated outputs.

## Before changing CI
1. Prefer adding jobs to the single workflow (e.g. `.github/workflows/ci.yml`) over creating new workflow files.
2. Run `curated.ps1 doctor` and `curated.ps1 scan` locally to confirm checks still pass.

## After setup script changes
1. Run `curated.ps1 setup` (or bootstrap on a test path) to verify.
2. Run `curated.ps1 test` to ensure gen-rules, doctor, scan, and rules are OK.
3. Run `scripts/run-tests.ps1` to run the unit test suite (Pester or fallback).

## Releasing
1. Bump version; run `curated.ps1 release -ReleaseVersion <ver>`.
2. Zip is under `dist/dev-kit-<ver>.zip`.
