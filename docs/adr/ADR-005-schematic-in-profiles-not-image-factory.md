# ADR-005: schematic.yaml lives in profiles/, not image-factory/

**Date:** 2026-06-29  
**Status:** Accepted  
**Deciders:** Arash Kaffamanesh, GPT and Claude  
**Related:** [OK-45](https://kubernauts.atlassian.net/browse/OK-45)

---

## Context

When implementing Phase 2 (Image Factory), the schematic files needed a home in the repository. Two structures were considered:

**Option A — Separate image-factory/ directory (GPT initial suggestion):**
```
ok-linux/
├── profiles/
│   └── kubevirt/
│       └── profile.yaml
└── image-factory/
    └── kubevirt/
        └── schematic.yaml
```

**Option B — Schematic inside profiles/ (adopted):**
```
ok-linux/
└── profiles/
    └── kubevirt/
        ├── profile.yaml
        └── schematic.yaml
```

## Decision

> `schematic.yaml` lives inside `profiles/<name>/` alongside `profile.yaml`, not in a separate top-level `image-factory/` directory.

## Rationale

- **Cohesion:** A profile is the complete description of a node type. `profile.yaml` references the schematic ID; `schematic.yaml` defines what generates it. They are two aspects of the same thing — separating them into different directories creates artificial distance.
- **User-facing abstraction vs internal implementation:** A separate `image-factory/` directory mirrors the internal workflow (submit schematic → get ID) rather than the user-facing concept (this is the kubevirt profile). The user thinks in profiles, not in factory submissions.
- **Discoverability:** When a contributor opens `profiles/kubevirt/`, they immediately see all artifacts for that profile: `profile.yaml`, `schematic.yaml`, `machineconfig.yaml`, `README.md`. Nothing is hidden in a parallel directory tree.
- **`make build PROFILE=kubevirt` is self-evident** — the profile name is the unit of work. A separate `image-factory/` directory would suggest a separate workflow that doesn't exist.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| `image-factory/<name>/schematic.yaml` | Mirrors internal implementation; splits cohesive profile artifacts across directories; confusing for new contributors |
| `schematics/<name>.yaml` | Flat structure loses the profile grouping; doesn't scale to per-profile subdirectories |

## Consequences

**Positive:**
- Each profile directory is fully self-contained
- New contributors find everything for a profile in one place
- `make build PROFILE=<name>` operates on a single directory

**Negative / trade-offs:**
- The Image Factory concept is not immediately visible from the top-level directory listing — someone looking for "image factory stuff" needs to know to look inside a profile

**Neutral:**
- `make show-all` iterates over `profiles/*/` — no change needed regardless of schematic placement
