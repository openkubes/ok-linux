# okl on Hetzner Bare Metal

## Supported Hardware

| Server | CPU | RAM | Storage | Role |
|--------|-----|-----|---------|------|
| AX42-U | AMD Ryzen 7 PRO 8700GE | 64-128GB DDR5 | 2x512GB NVMe Gen4 | ok-infra (server) |
| GEX44 | Intel Core i5-13500 | 64GB DDR4 | 2x1.92TB NVMe Gen3 | ok-gpu (agent + GPU) |

---

## Installation via Hetzner installimage

### 1. Activate Rescue System

In Hetzner Robot → Server → Rescue → Activate

### 2. SSH into Rescue System

```bash
ssh root@<server-ip>
```

### 3. Run installimage

```bash
installimage
```

Select:
- **OS:** Ubuntu 24.04 LTS
- **RAID:** Software RAID 1 (recommended)
- **Hostname:** `ok-infra` or `ok-gpu`

### 4. Apply okl configuration

After reboot, apply okl sysctl and kernel parameters:

```bash
# Clone ok-linux
git clone https://github.com/openkubes/ok-linux.git
cd ok-linux

# Install okl on this node
make install NODE=$(hostname)
```

---

## vSwitch Configuration

Hetzner vSwitch requires a VLAN interface. okl includes a Netplan template:

```bash
# ok-infra
cat > /etc/netplan/60-okl-vswitch.yaml << EOF
network:
  version: 2
  ethernets:
    enp0s31f6:
      dhcp4: false
      dhcp6: false
  vlans:
    enp0s31f6.4000:
      id: 4000
      link: enp0s31f6
      mtu: 1400
      addresses:
        - 192.168.100.2/24
      routes:
        - to: 192.168.0.0/16
          via: 192.168.100.1
EOF
chmod 600 /etc/netplan/60-okl-vswitch.yaml
netplan apply
```

---

## GRUB Parameters for Hetzner

Add to `/etc/default/grub`:

```bash
GRUB_CMDLINE_LINUX="iommu=pt intel_iommu=on amd_iommu=on vfio_iommu_type1.allow_unsafe_interrupts=1 kvm.ignore_msrs=1 net.ifnames=0"
```

Then:

```bash
update-grub
reboot
```

---

## GPU Node (GEX44)

For NVIDIA RTX 4000 Ada passthrough:

```bash
# Verify IOMMU is active
dmesg | grep -i iommu

# Check VFIO binding
lspci -nn | grep NVIDIA
echo "10de:27b0" > /sys/bus/pci/drivers/vfio-pci/new_id
```
