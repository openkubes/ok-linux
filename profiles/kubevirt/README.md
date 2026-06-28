# ok-linux Profile: kubevirt

Talos Linux profile for running Kubernetes nodes as **KubeVirt VMs** on OpenKubes bare-metal hosts.

This is the primary profile used by [ok-cluster](https://github.com/openkubes/ok-cluster) CAPK templates to provision workload clusters.

---

## Target environment

| Property | Value |
|---|---|
| Hypervisor | KubeVirt v1.8+ (QEMU/KVM) |
| Image format | `openstack-amd64.qcow2` |
| Bootstrap | CAPK + CloudInit ConfigDrive (OpenStack format) |
| Host OS | RKE2 or k3s on Hetzner bare metal |
| Tested on | ok-infra (AX42-U), ok-gpu (GEX44) |

---

## Profile

```yaml
talos:
  version: v1.9.5
  schematic_id: ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515
  image: factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.9.5

kernel_args:
  - console=ttyS0    # Required for QEMU serial console
  - net.ifnames=0    # Predictable interface naming off

machine_config:
  install:
    disk: /dev/vda   # virtio block device in KubeVirt VMs
  network:
    nameservers: [8.8.8.8, 1.1.1.1]
  time:
    servers: [time.cloudflare.com]
```

---

## Talos Image Factory

The schematic ID was generated from the [Talos Image Factory](https://factory.talos.dev) with the following schematic:

```yaml
customization:
  systemExtensions:
    officialExtensions: []
```

No extensions are active in the base kubevirt profile. The base Talos image is sufficient for KubeVirt VMs.

To regenerate or verify the schematic ID:

```bash
# Submit schematic and get ID
curl -X POST \
  -H "Content-Type: application/yaml" \
  --data-binary @schematic.yaml \
  https://factory.talos.dev/schematics
```

---

## Usage in ok-cluster

The CAPK `KubevirtMachineTemplate` references this profile's image URL:

```yaml
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: KubevirtMachineTemplate
spec:
  template:
    spec:
      virtualMachineBootstrapCheck:
        checkStrategy: none
      virtualMachineTemplate:
        spec:
          runStrategy: Always
          template:
            spec:
              domain:
                devices: {}
              volumes:
                - name: containervolume
                  containerDisk:
                    image: factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.9.5
```

---

## Tested cluster configurations

| Cluster | Talos | Kubernetes | Nodes | Status |
|---|---|---|---|---|
| ok1-talos | v1.9.x | v1.36.2 | 3 CP + 2 Worker | ✅ stable |

---

## Known constraints

- VMs must run on `ok-gpu` (GEX44) — ok-infra has QEMU serial console issues
- Install disk is always `/dev/vda` (virtio) — not `/dev/sda`
- `console=ttyS0` kernel arg is required for CAPK bootstrap readiness check
- CAPK uses `cloudInitConfigDrive` (OpenStack format) — Talos reads this correctly via `openstack-amd64.qcow2`

---

## Optional extensions

| Extension | Purpose | Reference |
|---|---|---|
| `qemu-guest-agent` | Disk info, freeze/thaw for snapshots | [OK-50](https://kubernauts.atlassian.net/browse/OK-50) |

To add an extension, update `schematic.yaml` in `../../image-factory/kubevirt/` (Phase 2) and regenerate the schematic ID.

---

## Upgrading Talos

1. Update `talos.version` in `profile.yaml`
2. Regenerate `schematic_id` via Image Factory if extensions changed
3. Update `talos.image` URL
4. Run `make upgrade CLUSTER=<name>` in ok-cluster

Tracked in: [OK-47](https://kubernauts.atlassian.net/browse/OK-47) (versioning)
