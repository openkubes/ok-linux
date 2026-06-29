# ADR-003: GPU as a first-class profile

**Date:** 2026-06-29  
**Status:** Accepted  
**Deciders:** Arash Kaffamanesh, GPT architectural review  
**Related:** [OK-37](https://kubernauts.atlassian.net/browse/OK-37), [OK-49](https://kubernauts.atlassian.net/browse/OK-49)

---

## Context

OpenKubes runs a dedicated GPU node: ok-gpu (Hetzner GEX44, RTX 4000 Ada, `192.168.100.3`). When defining how GPU support should be modelled in ok-linux, two approaches were considered:

1. **Extension approach:** `profile: baremetal` + `extensions: [nvidia]` — GPU is a variant of bare metal
2. **Profile approach:** `profile: gpu` — GPU is its own node type with a dedicated profile

## Decision

> GPU nodes get their own first-class profile (`profiles/gpu/`) rather than being modelled as an extension on top of `baremetal/`.

## Rationale

- **A GPU node is a distinct node type**, not a bare-metal node with an add-on. It has its own:
  - Kernel args (IOMMU, VFIO settings)
  - Extensions (`nvidia-container-toolkit`, `nvidia-open-gpu-kernel-modules`)
  - MachineConfig (containerd GPU runtime configuration)
  - Node labels (`nvidia.com/gpu=true`, `ok-linux/profile=gpu`)
  - Taints (`nvidia.com/gpu=true:NoSchedule`)
- **Extensions add software; profiles define node identity.** The nvidia extension is part of the GPU profile's schematic — the distinction is that the profile *as a whole* represents a GPU node, not just the extension.
- **Future GPU types are natural additions**, not variants of `baremetal/`:
  - AMD ROCm → `profiles/gpu-amd/`
  - NVIDIA Jetson → `profiles/gpu-jetson/`
  - Intel GPU → `profiles/gpu-intel/`
  
  These are parallel profiles, not nested extensions. Adding them does not require modifying `baremetal/`.
- **ok-cluster clarity:** `profile: gpu` immediately communicates node intent. `profile: baremetal` with a separate extension list is ambiguous and harder to validate.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| `profile: baremetal` + `extensions: [nvidia]` | GPU node identity is lost; future GPU variants become increasingly complex extension combinations |
| Single `baremetal` profile with GPU variant flag | Flags are anti-patterns in declarative configuration; adds conditional logic to profiles |

## Consequences

**Positive:**
- GPU node requirements are fully self-contained in `profiles/gpu/`
- ok-cluster can request `profile: gpu` without knowing any NVIDIA-specific details
- Future GPU architectures (AMD, Jetson, Intel) are clean parallel additions
- Node labels and taints are part of the profile definition — no separate configuration step

**Negative / trade-offs:**
- An additional profile to maintain
- Some duplication with `baremetal/` (e.g. Hetzner-specific disk paths) — acceptable, as the node type is genuinely different

**Neutral:**
- The `profiles/gpu/` directory is currently `planned` — implementation follows when ok-gpu runs Talos bare metal
