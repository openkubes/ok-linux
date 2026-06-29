# ADR-002: Profiles as the primary abstraction

**Date:** 2026-06-16  
**Status:** Accepted  
**Deciders:** Arash Kaffamanesh, GPT and Claude architectural review  
**Related:** [OK-37](https://kubernauts.atlassian.net/browse/OK-37), [OK-42](https://kubernauts.atlassian.net/browse/OK-42)

---

## Context

Once Talos was selected as the base OS (ADR-001), the question became: how should ok-linux organise and expose OS configurations to ok-cluster?

Three options were considered:
1. A single global Talos configuration for all OpenKubes nodes
2. Per-cluster configuration — each cluster defines its own OS parameters
3. Named profiles — reusable, environment-specific OS configurations

## Decision

> The primary abstraction in ok-linux is a "profile" — a named, declarative OS configuration for a specific target environment.

## Rationale

- **Single global config is too coarse** — KubeVirt VMs (virtio disk, serial console, QEMU guest agent) and bare-metal servers (NVMe disk, iPXE boot, no virtualisation) are fundamentally different node types. One config cannot express both correctly.
- **Per-cluster config creates duplication** — if every cluster defines its own OS parameters, updating the Talos version or schematic ID requires touching every cluster. This is error-prone and inconsistent.
- **Profiles are the right granularity** — they capture what's different about a *node type*, not a specific cluster. Multiple clusters can reference `profile: kubevirt` and all receive the same verified OS configuration.
- **Profiles are reusable and testable** — a profile can be verified against a running cluster (`make verify PROFILE=kubevirt`) independently of any specific cluster deployment.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Single global config | Cannot express different node types (KubeVirt vs bare metal vs GPU) |
| Per-cluster OS config | Duplicates configuration, makes version updates error-prone |
| Per-node config | Too granular — individual nodes should not differ within a cluster |

## Consequences

**Positive:**
- ok-cluster only needs to reference `profile: kubevirt` — no Talos-specific knowledge required
- Profiles are independently versioned and verifiable
- New environments (edge, GPU) are added as new profiles — ok-cluster does not change
- Profiles serve as documentation of what each node type requires

**Negative / trade-offs:**
- Profile names must be stable — renaming a profile is a breaking change
- Profile granularity decisions require upfront thought (e.g. is GPU a profile or an extension? — see ADR-003)

**Neutral:**
- Profiles are YAML files — no tooling beyond a text editor and `make` is required to work with them
