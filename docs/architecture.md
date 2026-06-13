# okl Architecture

## Overview

okl (OpenKubes Linux) is the OS foundation of the OpenKubes stack:

```
┌─────────────────────────────────────────────┐
│              OpenKubes Platform              │
│   Crossplane · CAPI · KubeVirt · MetalLB    │
├─────────────────────────────────────────────┤
│                    OKE                       │
│         Kubernetes Distribution              │
├─────────────────────────────────────────────┤
│                   okl 🐧                     │
│         OpenKubes Linux                      │
│  ┌──────────┬──────────┬──────────────────┐ │
│  │ok-kernel │ ok-image │    ok-boot       │ │
│  │KVM·VFIO  │cloud-init│ PXE · iPXE       │ │
│  │IOMMU·SR  │golden img│ GRUB             │ │
│  └──────────┴──────────┴──────────────────┘ │
├─────────────────────────────────────────────┤
│              Hetzner Bare Metal              │
│         AX42-U · GEX44 · vSwitch            │
└─────────────────────────────────────────────┘
```

---

## Components

### ok-kernel

Custom kernel configuration optimized for OpenKubes nodes:

- **KVM** — hardware virtualization for KubeVirt VMs
- **VFIO** — GPU and PCIe device passthrough
- **IOMMU** — AMD/Intel IOMMU for device isolation
- **SR-IOV** — network card virtualization
- **WireGuard** — built-in VPN support
- **cgroup v2** — Kubernetes resource management
- **Overlay FS** — container image layers

### ok-image

Golden image pipeline:

```
Ubuntu 24.04 LTS base
        │
   okl customization
   ├── okl kernel config
   ├── cloud-init templates
   ├── pre-installed packages
   └── sysctl / modules
        │
   okl golden image
   ├── Hetzner Bare Metal
   ├── KubeVirt VM
   └── Proxmox VM
```

### ok-boot

Boot support for automated provisioning:

- **iPXE** — network boot for Hetzner Bare Metal
- **GRUB** — local boot with IOMMU parameters
- **cloud-init** — node configuration on first boot

---

## Kernel Parameters

Critical kernel parameters for OpenKubes nodes:

```bash
# GRUB_CMDLINE_LINUX in /etc/default/grub
iommu=pt              # IOMMU passthrough mode
intel_iommu=on        # Enable Intel IOMMU
amd_iommu=on          # Enable AMD IOMMU
vfio_iommu_type1.allow_unsafe_interrupts=1  # VFIO
kvm.ignore_msrs=1     # KVM compatibility
net.ifnames=0         # Consistent NIC naming
```

---

## Node Types

| Type | Use Case | Key Features |
|------|----------|-------------|
| `server` | OKE control plane | ETCD, API server |
| `agent` | OKE worker | Container workloads |
| `gpu-agent` | GPU workloads | VFIO passthrough, NVIDIA |
| `edge` | Edge deployment | Minimal footprint |
