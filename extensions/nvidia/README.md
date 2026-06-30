# Extension: nvidia

**Status:** 📋 Planned  
**Profile:** gpu (first-class profile — see [ok-linux ADR-003](../../docs/adr/ADR-003-gpu-first-class-profile.md))  
**Upstream:** [siderolabs/extensions — nvidia-open-gpu-kernel-modules](https://github.com/siderolabs/extensions/tree/main/nonfree-kmod/nvidia-open-gpu-kernel-modules), [nvidia-container-toolkit](https://github.com/siderolabs/extensions/tree/main/nonfree-kmod/nvidia-container-toolkit)  
**Jira:** [OK-49](https://kubernauts.atlassian.net/browse/OK-49)

---

## Purpose

Enables NVIDIA GPU workloads on Talos nodes — required for AI/ML inference, training, and GPU-accelerated compute. Two extensions work together:

- **nvidia-open-gpu-kernel-modules** — the open-source NVIDIA kernel driver, loaded at boot
- **nvidia-container-toolkit** — exposes the GPU to containers via the container runtime (`nvidia-ctk`, device plugin compatibility)

Per [ADR-003](../../docs/adr/ADR-003-gpu-first-class-profile.md), GPU support is implemented as its own profile (`profiles/gpu/`), not as an extension bolted onto `profiles/baremetal/`. This extension directory describes what goes *into* that profile's schematic — the GPU profile is the node identity, this extension is the software that makes it work.

---

## Target hardware

| Server | GPU | Status |
|---|---|---|
| ok-gpu (Hetzner GEX44) | NVIDIA RTX 4000 Ada | 📋 planned — Talos bare-metal migration not yet complete |

---

## Compatibility matrix

| Talos version | NVIDIA driver | Status | Notes |
|---|---|---|---|
| v1.9.5 | TBD | 📋 not yet tested | Pending: ok-gpu running RKE2, not yet migrated to Talos bare metal |

---

## Open prerequisites (tracked separately)

- [ ] `profiles/gpu/profile.yaml` and `profiles/gpu/schematic.yaml` created (this extension's consumer)
- [ ] ok-gpu (GEX44) provisioned with Talos bare-metal profile
- [ ] Node labels (`nvidia.com/gpu=true`) and taints (`nvidia.com/gpu=true:NoSchedule`) documented in `profiles/gpu/profile.yaml`
- [ ] `make build PROFILE=gpu` run and schematic ID verified against a running cluster

---

## How it will be wired

```yaml
# profiles/gpu/schematic.yaml (planned)
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/nvidia-open-gpu-kernel-modules
      - siderolabs/nvidia-container-toolkit
```

This extension cannot be marked stable until `profiles/gpu/` exists and has been verified on ok-gpu.
