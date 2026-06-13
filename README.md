# ok-linux 🐧

> **OpenKubes Linux — The OS that knows it's running Kubernetes.**

A minimal, KubeVirt-optimized Linux OS for OpenKubes infrastructure nodes.  
Designed for one purpose: running OpenKubes reliably, securely and consistently across bare metal, edge and cloud.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Jira](https://img.shields.io/badge/jira-OK--37-blue)](https://kubernauts.atlassian.net/browse/OK-37)

---

## Vision

Most Linux distributions are general-purpose. ok-linux is not.

ok-linux is an infrastructure OS built specifically for OpenKubes nodes — with KubeVirt, GPU passthrough, Hetzner Bare Metal and edge environments as first-class targets.

Inspired by [Talos Linux](https://www.talos.dev/), but OpenKubes-native:

- **Hetzner-aware** — vSwitch, VLAN, installimage compatible
- **KubeVirt-optimized** — kernel parameters, nested virt, IOMMU out of the box
- **GPU-ready** — NVIDIA VFIO passthrough, SR-IOV support
- **Minimal** — no unnecessary packages, minimal attack surface
- **Makefile-driven** — consistent interface across all components

---

## Components

| Component | Description |
|-----------|-------------|
| **ok-kernel** | Custom kernel with KVM, VFIO, SR-IOV, DPDK, KubeVirt patches |
| **ok-image** | Golden image pipeline for Bare Metal + Cloud |
| **ok-boot** | PXE/iPXE boot for automated provisioning |
| **ok-hardening** | Minimal attack surface, SSH hardening, sysctl tuning |

---

## Target Platforms

- Hetzner Bare Metal (AX42-U, GEX44)
- Proxmox VMs
- KubeVirt VMs
- Edge devices

---

## Makefile Interface

```bash
make kernel    # Build ok-linux kernel
make image     # Build golden image
make boot      # PXE boot provisioning
make install   # Full node provisioning via ok-rke2 (RocketLab)
make help      # Show all targets
```

---

## Relationship to ok-rke2

ok-linux and [ok-rke2](https://github.com/openkubes/ok-rke2) are complementary:

```
ok-linux   →  The OS layer     (kernel, image, boot)
ok-rke2    →  The cluster layer (RKE2 install, vSwitch, GPU labels)
```

Together they form the foundation of an OpenKubes INFRA node:

```bash
# 1. Boot node with ok-linux
make boot node=ok-infra

# 2. Deploy RKE2 cluster
cd ../ok-rke2 && make install
```

---

## Status

🚧 **Early Design Phase** — contributions and ideas welcome.

---

## Part of OpenKubes

ok-linux is part of the [OpenKubes](https://github.com/openkubes/openkubes) platform —  
AI-Native Runtime Infrastructure for Sovereign Edge, Industrial Systems and Next-Generation Compute.

---

## License

Apache 2.0 — see [LICENSE](LICENSE)
