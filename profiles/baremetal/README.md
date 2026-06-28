# ok-linux Profile: baremetal

Talos Linux profile for running Kubernetes nodes directly on **physical servers** — no hypervisor layer.

Primary use case: OpenKubes management and host cluster nodes on Hetzner dedicated servers.

---

## Target environment

| Property | Value |
|---|---|
| Hardware | Hetzner AX42-U, GEX44 (and compatible) |
| Boot method | Hetzner installimage / iPXE / rescue mode |
| Image format | `metal-amd64` ISO or disk image |
| Networking | Public IP + vSwitch (VLAN 4000) + WireGuard VPN |
| Tested on | ok-infra (AX42-U, `188.40.110.28`), ok-gpu (GEX44, `5.9.116.80`) |

---

## Profile

```yaml
talos:
  version: v1.9.5
  schematic_id: ""   # TODO: generate via Image Factory (OK-45)
  image: ""          # TODO: set after schematic generation

kernel_args:
  - net.ifnames=0
  - talos.platform=metal

machine_config:
  install:
    disk: /dev/nvme0n1   # Hetzner AX/EX primary NVMe
  network:
    nameservers: [8.8.8.8, 1.1.1.1]
  time:
    servers: [time.cloudflare.com]
```

---

## Hetzner provisioning notes

### Initial bootstrap

Hetzner bare-metal servers require rescue mode for the initial Talos installation:

1. Activate rescue mode via [Hetzner Robot](https://robot.hetzner.com)
2. Boot into rescue system (Debian-based)
3. Download Talos metal image and write to disk:

```bash
# On the rescue system
curl -LO https://factory.talos.dev/image/<schematic_id>/v1.9.5/metal-amd64.raw.zst
zstd -d metal-amd64.raw.zst | dd of=/dev/nvme0n1 bs=4M status=progress
reboot
```

4. Apply MachineConfig via `talosctl`:

```bash
talosctl apply-config \
  --insecure \
  --nodes <public-ip> \
  --file controlplane.yaml
```

### Disk configuration

| Server | Primary disk | Path |
|---|---|---|
| AX42-U (ok-infra) | Samsung NVMe | `/dev/nvme0n1` |
| GEX44 (ok-gpu) | Samsung NVMe | `/dev/nvme0n1` |

### Network topology

```
Internet
    │
    ├── ok-infra  188.40.110.28  (public)
    │             192.168.100.2  (vSwitch VLAN 4000)
    │
    └── ok-gpu    5.9.116.80     (public)
                  192.168.100.3  (vSwitch VLAN 4000)

WireGuard VPN: ok-vpn (167.233.52.138) → 10.0.0.1
Mac client: 10.0.0.2
```

---

## Optional extensions

| Extension | Purpose | Reference |
|---|---|---|
| `nvidia` | GPU workloads (RTX 4000 Ada on ok-gpu) | [OK-49](https://kubernauts.atlassian.net/browse/OK-49) |
| `iscsi-tools` | iSCSI storage backend | planned |
| `intel-gpu` | Intel integrated GPU | planned |

---

## Known constraints

- `talosctl` must be run from within the WireGuard VPN or directly via public IP during bootstrap
- Hetzner vSwitch L2 isolation: macvlan/ipvlan causes unidirectional traffic — use Linux bridge or avoid Multus on management VMs
- Ansible `lineinfile` is fragile for netplan — use Jinja2 templates (learned from ok-gpu outage)
- rpcbind must be masked post-install (BSI alert remediation): `systemctl mask --now rpcbind`

---

## Schematic ID

The schematic ID for this profile is pending Image Factory integration (OK-45).

For the base metal profile (no extensions), submit an empty schematic:

```yaml
customization:
  systemExtensions:
    officialExtensions: []
```

For GPU nodes (ok-gpu), submit with nvidia extension:

```yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/nvidia-container-toolkit
```

---

## Status

🚧 In progress — schematic ID pending, tested configuration based on existing RKE2 host cluster setup.

Tracked in: [OK-43](https://kubernauts.atlassian.net/browse/OK-43)
