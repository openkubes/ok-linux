# ADR-004: Schematic ID resolution — static now, dynamic later

**Date:** 2026-06-29  
**Status:** Accepted  

---

## Context

ok-linux is the source of truth for Talos schematic IDs. ok-cluster needs the schematic ID to render the `KubevirtMachineTemplate`. The question is: how does the schematic ID get from ok-linux into ok-cluster?

Two approaches were considered:
1. **Static:** The operator runs `make build PROFILE=kubevirt` in ok-linux, copies the resulting schematic ID into `cluster-config.yaml`, and commits it.
2. **Dynamic:** ok-cluster's `render.py` fetches the schematic ID from ok-linux at render time (via GitHub raw URL, Git submodule, or API).

## Decision

> The schematic ID is set manually in `cluster-config.yaml` today. The `os.schematic_id` field is the seam between static and dynamic resolution. Dynamic resolution is deferred to a future release.

## Rationale

- **Static is safe and reproducible** — the schematic ID in `cluster-config.yaml` is explicit, auditable, and does not depend on network availability at render time.
- **Dynamic adds complexity prematurely** — fetching from ok-linux at render time requires: network access, error handling, caching, and version pinning logic. None of this is needed for v0.1.0.
- **The seam is already defined** — `render.py` reads `schematic_id` from `cluster-config.yaml` with a clear priority chain: `config → env → fallback`. Switching to dynamic resolution later only requires changing how `render.py` populates this value — no template changes.
- **Explicit is better than implicit** — after running `make build`, the operator consciously updates `cluster-config.yaml`. This is a deliberate gate that prevents accidental OS changes in running clusters.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Dynamic resolution at render time | Premature complexity; network dependency; requires caching and error handling |
| Git submodule pointing to ok-linux | Submodule management overhead; still requires a manual update step |
| Environment variable only | Works for CI but not for reproducible local renders |

## Consequences

**Positive:**
- Schematic ID changes are always explicit and auditable in git history
- No network dependency during `make render`
- Migration to dynamic resolution requires no template changes — only `render.py`

**Negative / trade-offs:**
- After every `make build PROFILE=kubevirt`, the operator must manually copy the schematic ID into `cluster-config.yaml` — a two-step process

**Neutral:**
- The `os.schematic_id` field name and position in `cluster-config.yaml` are permanent — they form the API contract between ok-cluster and ok-linux
