# Project

Governance contract: lockfile required; single CI entrypoint (`.github/workflows/ci.yml`); one rewriter per extension.

## Setup
- `git init` (if not already)
- Add lockfile: `bun install` / `npm install` / `uv lock` as appropriate
- CI runs on push via `.github/workflows/ci.yml`
