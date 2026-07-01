# ADR-001: Talos Linux as the base OS

**Date:** 2026-06-13  
**Status:** Accepted  

---

## Context

ok-linux began as a custom Linux distribution for OpenKubes infrastructure nodes. The original approach (now in `archive/`) included:
- A custom kernel configuration (`okl-kernel.config`)
- PXE boot scripts (`okl.ipxe`, `grub.cfg`)
- A Cloud-Init image pipeline (`build.sh`, `user-data.yaml`)

This approach required maintaining a full OS build pipeline, kernel patches, and a custom image format. As OpenKubes grew, the maintenance burden became disproportionate to the value delivered.

The question arose: should ok-linux build and maintain its own OS layer, or build on top of an existing immutable Kubernetes-native OS?

## Decision

> ok-linux builds on Talos Linux as its base OS. A custom kernel or OS build pipeline will not be maintained.

## Rationale

- **Talos is purpose-built for Kubernetes** — immutable, API-driven, no SSH, no shell. This aligns perfectly with OpenKubes' security and operational model.
- **Talos Image Factory** provides a reproducible, API-driven image pipeline. A POST to `factory.talos.dev/schematics` returns a deterministic schematic ID — better than a custom `build.sh`.
- **Upstream handles the hard parts** — kernel CVEs, Kubernetes compatibility, containerd updates, secure boot. ok-linux does not need to replicate this.
- **ok-linux adds value through curation** — selecting the right Talos extensions, defining MachineConfig defaults, and providing named profiles per environment. This is where the actual OpenKubes value lies.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Custom kernel (existing approach) | High maintenance burden, duplicates Talos upstream work, security CVE tracking required |
| Flatcar Linux | Good alternative, but less Kubernetes-native than Talos; no Image Factory equivalent |
| Ubuntu + kubeadm | Not immutable; mutable OS state creates operational complexity |
| Bottlerocket | AWS-centric; limited bare-metal and KubeVirt support |

## Consequences

**Positive:**
- Zero kernel maintenance burden — Talos upstream handles it
- Reproducible images via Image Factory — no local build environment needed
- Immutable nodes by default — no SSH, no mutable state
- ok-linux can focus on profiles, schematics, and MachineConfig — not OS internals

**Negative / trade-offs:**
- ok-linux is dependent on Talos upstream release cadence
- Any OS-level customisation not supported by Talos Extensions requires upstream contribution (or is rejected — see ADR-008)
- The `archive/` directory remains as historical context, but represents a dead end

**Neutral:**
- Talos schematic IDs must be managed explicitly — this is handled by the Image Factory contract (see ADR-005)
