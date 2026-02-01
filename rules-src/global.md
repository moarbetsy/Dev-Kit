# Repo-wide rules (single source of truth)
Edit here; `curated.ps1 gen-rules` copies to `.cursor/rules/*.mdc` and `cursor/ai-rules.txt`.

## General
- Write clean, maintainable code.
- Follow language-specific best practices.
- Prefer explicit over implicit; handle errors gracefully.

## Code style
- Meaningful variable and function names; small focused functions; early returns; composition over inheritance.
- Avoid deep nesting (max 3–4 levels).

## Testing
- Tests for critical functionality; descriptive test names; edge cases and error conditions.

## Documentation
- Document public APIs; keep README up to date; document non-obvious decisions.
