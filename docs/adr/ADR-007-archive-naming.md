# ADR-007: archive/ instead of _archive/

**Date:** 2026-06-29  
**Status:** Accepted  

---

## Context

When migrating from the custom kernel/image approach to Talos-based profiles, the old files (kernel config, PXE scripts, build.sh, cloud-init) needed to be preserved for historical reference without cluttering the active repository structure.

The question was whether to name the directory `_archive/` or `archive/`.

## Decision

> The historical files directory is named `archive/`, not `_archive/`.

## Rationale

- **`_archive/` implies "hidden from tooling"** — the underscore prefix is a convention used for build artifacts and generated files (e.g. `_build/`, `_site/`, `__pycache__/`). It signals "tooling should ignore this". That is not the intent — `archive/` is intentionally part of the repository for historical reference.
- **`archive/` is a standard English word** — it communicates intent clearly to any contributor, regardless of their familiarity with underscore conventions.
- **Git history is the real archive** — the files in `archive/` are there as a navigable snapshot of the previous approach, not as a recovery mechanism. Any contributor who wants the full history can use `git log`.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| `_archive/` | Underscore implies tooling-ignored; inconsistent with intent |
| Delete the files entirely | Loses the historical context visible in the repository without requiring `git log` |
| Keep files in original location with deprecation notice | Clutters active structure; makes the migration status unclear |

## Consequences

**Positive:**
- `archive/` clearly signals "historical, not active" to contributors
- No tooling is confused by the directory

**Negative / trade-offs:**
- None significant — this is a naming convention choice

**Neutral:**
- `archive/` is not referenced by any Makefile target, test, or documentation outside this ADR and `spec.md`
