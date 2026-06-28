# okl Kernel Patches

This directory contains kernel patches applied on top of the Ubuntu 24.04 LTS kernel for okl (OpenKubes Linux).

## Planned Patches

| Patch | Description | Status |
|-------|-------------|--------|
| `kubevirt-hugepages.patch` | Hugepage support optimizations for KubeVirt VMs | planned |
| `vfio-nvidia-reset.patch` | NVIDIA GPU reset fix for VFIO passthrough | planned |
| `hetzner-nic-naming.patch` | Consistent NIC naming on Hetzner Bare Metal | planned |
| `cgroup-v2-compat.patch` | cgroup v2 compatibility improvements | planned |

## Applying Patches

```bash
# Apply all patches
for patch in *.patch; do
  patch -p1 < "$patch"
done
```

## Contributing

New patches should:
- Target Ubuntu 24.04 LTS (6.8.x) kernel
- Include a description and motivation
- Be tested on Hetzner AX42-U or GEX44
