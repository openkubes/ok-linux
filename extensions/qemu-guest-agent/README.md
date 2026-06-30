# Extension: qemu-guest-agent

**Status:** ✅ Active  
**Profile:** kubevirt  
**Upstream:** [siderolabs/extensions — qemu-guest-agent](https://github.com/siderolabs/extensions/tree/main/guest-agents/qemu-guest-agent)  
**Jira:** [OK-50](https://kubernauts.atlassian.net/browse/OK-50)

---

## Purpose

QEMU Guest Agent runs inside the Talos VM and communicates with the KubeVirt/libvirt host. It enables:

- Disk usage and filesystem info reporting to KubeVirt
- Freeze/thaw coordination for consistent VM snapshots
- Graceful shutdown signalling from the host

Without this extension, KubeVirt cannot query in-guest disk state or coordinate snapshot-consistent freezes — VM snapshots would only be crash-consistent, not application-consistent.

---

## Compatibility matrix

| Talos version | Status | Notes |
|---|---|---|
| v1.9.5 | ✅ verified | Active in `profiles/kubevirt/schematic.yaml`, schematic ID `ce4c980...` |

---

## Tested configurations

| Cluster | Talos | Status |
|---|---|---|
| ok1-talos | v1.9.5 | ✅ production — schematic ID matches running cluster |

---

## How it's wired

This extension is part of the base `profiles/kubevirt/schematic.yaml` — it is not optional for the kubevirt profile, since every KubeVirt VM benefits from guest-agent integration.

```yaml
# profiles/kubevirt/schematic.yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/qemu-guest-agent
```

To verify the schematic ID still matches:

```bash
make verify PROFILE=kubevirt
```
