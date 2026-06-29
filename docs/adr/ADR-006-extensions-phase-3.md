# ADR-006: Extensions come after Phase 2

**Date:** 2026-06-29  
**Status:** Accepted  
**Deciders:** Arash Kaffamanesh, GPT architectural review  
**Related:** [OK-48](https://kubernauts.atlassian.net/browse/OK-48), [OK-49](https://kubernauts.atlassian.net/browse/OK-49), [OK-50](https://kubernauts.atlassian.net/browse/OK-50)

---

## Context

ok-linux uses Talos extensions to add software to OS images (e.g. `qemu-guest-agent`, `nvidia-container-toolkit`). The question was: should extension governance and a formal `extensions/` directory structure be part of Phase 1 or 2, or deferred to Phase 3?

## Decision

> Extension governance and the `extensions/` directory structure are Phase 3 — after profiles and Image Factory are stable.

## Rationale

- **Profiles and schematics are declarative** — once a profile is defined and its schematic verified, it requires no ongoing maintenance. A profile is stable.
- **Extensions are software** — they require:
  - Security update tracking (CVE monitoring per extension)
  - Compatibility testing with each Talos minor version
  - Deprecation planning when upstream drops support
  - Release cadence alignment with Talos releases
- **Starting with extensions creates premature obligations** — before the profile foundation is stable, maintaining extension governance adds overhead without proportional benefit.
- **The qemu-guest-agent exception:** This extension is already active in the kubevirt schematic (`ce4c980...`). The correct model — for now — is: extensions live *in schematics*, not as separate directory artifacts. Phase 3 formalises this into an `extensions/<name>/` structure when the maintenance overhead justifies the organisation.
- **GPU (nvidia) is the natural trigger for Phase 3** — when `profiles/gpu/` is implemented, the nvidia extension must be formally governed. That is the right moment to establish the `extensions/` structure.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Extensions in Phase 1 | Creates maintenance obligations before the foundation is stable |
| Extensions in Phase 2 | Image Factory phase is already scope-complete without extensions |
| No formal extension governance ever | Unmanaged extensions accumulate security debt; not viable for production |

## Consequences

**Positive:**
- Phase 1 and 2 ship without extension maintenance overhead
- Extension governance criteria are defined deliberately rather than reactively
- The `extensions/` directory structure is introduced when it is actually needed

**Negative / trade-offs:**
- `qemu-guest-agent` is active in production (ok1-talos) but not formally governed until Phase 3 — acceptable for v0.1.0 since it is embedded in the schematic and verified

**Neutral:**
- Extensions referenced in `schematic.yaml` files continue to work regardless of Phase 3 status — the `extensions/` directory is governance infrastructure, not runtime infrastructure
