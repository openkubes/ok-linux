# ok-linux

**ok-linux** is the Kubernetes Host OS layer of [OpenKubes](https://github.com/openkubes/openkubes).

It defines *which operating system* runs on OpenKubes nodes — independent of *how* clusters are provisioned ([ok-cluster](https://github.com/openkubes/ok-cluster)).

> ok-linux is not a general-purpose Linux distribution.
> It is a curated set of [Talos Linux](https://www.talos.dev/) profiles, image factory schematics, and extensions — optimized for running Kubernetes nodes on bare metal, KubeVirt, and edge environments.

---

## Architecture

```
ok-linux/
├── profiles/          # Declarative OS profiles per target environment
│   ├── kubevirt/      # Talos VMs under KubeVirt (QEMU/KVM)
│   ├── baremetal/     # Physical servers (Hetzner AX/EX)
│   └── edge/          # Single-node, IoT, ROS2 (draft)
│
├── image-factory/     # Talos Image Factory schematics (Phase 2)
│   ├── kubevirt/
│   └── baremetal/
│
└── extensions/        # Curated Talos extensions (Phase 3)
    ├── nvidia/
    └── qemu-guest-agent/
```

---

## Profiles (Phase 1)

Each profile is a declarative YAML file describing:

| Field | Description |
|---|---|
| `talos.version` | Talos Linux version |
| `talos.schematic_id` | Talos Image Factory schematic ID |
| `talos.image` | Full image URL for provisioning |
| `kernel_args` | Kernel arguments |
| `machine_config` | MachineConfig defaults (disk, network, time) |
| `extensions` | Active Talos extensions |

### Available profiles

| Profile | Target | Status |
|---|---|---|
| `kubevirt` | Talos VMs under KubeVirt | ✅ stable |
| `baremetal` | Hetzner AX/EX bare metal | 🚧 in progress |
| `edge` | IoT / single-node / ROS2 | 📋 draft |

---

## Integration with ok-cluster

[ok-cluster](https://github.com/openkubes/ok-cluster) references ok-linux profiles instead of raw Talos schematic IDs:

```yaml
# ok-cluster cluster config (Phase 2+)
os:
  distribution: ok-linux
  profile: kubevirt
  version: v1.0
```

ok-cluster resolves this to the concrete Talos schematic ID and image URL internally.

---

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 — Profiles | Declarative OS profiles per environment | 🚧 active |
| 2 — Image Factory | Reproducible Talos images via schematics | 📋 planned |
| 3 — Extensions | Curated Talos extensions (nvidia, qemu-guest-agent, …) | 📋 planned |

Tracked in Jira: [OK-37](https://kubernauts.atlassian.net/browse/OK-37)

---

## Related repositories

| Repository | Description |
|---|---|
| [ok-cluster](https://github.com/openkubes/ok-cluster) | Cluster lifecycle engine (CAPI/CAPK) |
| [ok-local](https://github.com/openkubes/ok-local) | Local development environment |
| [openkubes](https://github.com/openkubes/openkubes) | Architecture, docs, vision |

---

## License

Apache 2.0 — see [LICENSE](LICENSE)
