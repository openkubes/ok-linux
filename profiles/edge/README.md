# ok-linux Profile: edge

> **Status: 📋 Draft — not production ready**

Talos Linux profile placeholder for **edge deployments** — single-node clusters, IoT gateways, robotics, and resource-constrained environments.

Tracked in: [OK-44](https://kubernauts.atlassian.net/browse/OK-44)

---

## Intended use cases

| Use case | Description |
|---|---|
| Single-node Kubernetes | No HA control plane, minimal footprint |
| IoT gateway | Edge data collection and processing |
| Robotics (ROS2) | Robot Operating System 2 on Kubernetes |
| Air-gapped / offline | Disconnected environments without internet access |
| ARM64 devices | Raspberry Pi, NVIDIA Jetson, and similar |

---

## Differences from other profiles

| Property | kubevirt | baremetal | edge |
|---|---|---|---|
| Hypervisor | KubeVirt/QEMU | none | none |
| HA control plane | yes | yes | no (single-node) |
| GPU support | via KubeVirt | nvidia extension | intel-gpu / jetson |
| Boot method | CAPK/CloudInit | Hetzner rescue | iPXE / USB / SD card |
| ARM64 support | no | no | planned |

---

## Open questions

- [ ] ARM64 schematic via Talos Image Factory (`metal-arm64`)
- [ ] Minimal extension set for constrained hardware (< 4GB RAM)
- [ ] Offline image factory workflow for air-gapped deployments
- [ ] ROS2 runtime extension availability in Talos catalog
- [ ] Single-node cluster bootstrap via `talosctl` without CAPI

---

## Potential extensions

| Extension | Purpose |
|---|---|
| `ros2-runtime` | Robot Operating System 2 |
| `intel-gpu` | Intel integrated GPU inference |
| `gasket-driver` | Google Coral TPU (Edge AI) |

---

## Contributing

If you have an edge use case you'd like to see supported, open an issue at [openkubes/ok-linux](https://github.com/openkubes/ok-linux/issues) with:

- Hardware description
- Use case and workload type
- Any existing Talos configuration you've tested

---

## Related

- [Talos ARM64 support](https://www.talos.dev/latest/talos-guides/install/single-board-computers/)
- [Talos single-node cluster](https://www.talos.dev/latest/introduction/getting-started/)
- [Siderolabs Extensions catalog](https://github.com/siderolabs/extensions)
