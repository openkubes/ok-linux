# ok-linux

**ok-linux** is the Kubernetes Host OS layer of [OpenKubes](https://github.com/openkubes/openkubes).

It provides **Talos Linux profiles**, **Image Factory schematics**, and **MachineConfig presets** — optimized for running Kubernetes nodes on bare metal, KubeVirt, and edge environments.

> ok-linux is not a general-purpose Linux distribution.
> It is a curated OS abstraction on top of [Talos Linux](https://www.talos.dev/) —
> so that [ok-cluster](https://github.com/openkubes/ok-cluster) only needs to say:
>
> ```yaml
> os:
>   distribution: ok-linux
>   profile: kubevirt
> ```

---

## Repository structure

```
ok-linux/
├── profiles/          # Declarative OS profiles per target environment
│   ├── kubevirt/      # Talos VMs under KubeVirt (QEMU/KVM)       ✅
│   ├── baremetal/     # Physical servers (Hetzner AX/EX)           ✅
│   ├── edge/          # Single-node, IoT, ROS2                     📋 draft
│   └── gpu/           # GPU nodes (RTX 4000 Ada, first-class)      📋 planned
│
├── extensions/        # Curated Talos extensions (Phase 3)
│   ├── nvidia/
│   └── qemu-guest-agent/
│
├── docs/
│   ├── architecture.md
│   └── roadmap.md
│
├── archive/           # Previous custom kernel/image approach (historical)
└── Makefile
```

---

## Profiles

Each profile is a declarative YAML describing the complete OS configuration for a node type:

| Profile | Target | Status |
|---|---|---|
| `kubevirt` | Talos VMs under KubeVirt | ✅ stable |
| `baremetal` | Hetzner AX/EX bare metal | 🚧 in progress |
| `edge` | IoT / single-node / ROS2 | 📋 draft |
| `gpu` | GPU nodes (RTX 4000 Ada) | 📋 planned |

Each profile contains (Phase 1 → Phase 2):

```
profiles/kubevirt/
├── profile.yaml        # Talos version, schematic ID, kernel args, extensions
├── schematic.yaml      # Talos Image Factory input (Phase 2)
├── machineconfig.yaml  # MachineConfig defaults for ok-cluster (Phase 2)
└── README.md
```

---

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| **1 — Profiles** | Declarative OS profiles per environment | ✅ done |
| **2 — Image Factory** | Reproducible images, `make build/show PROFILE=` | 📋 planned |
| **3 — Extensions** | Curated extensions with governance | 📋 planned |

→ See [docs/roadmap.md](docs/roadmap.md) for details.

---

## Role separation

| Repository | Responsibility |
|---|---|
| **ok-linux** | OS profiles, schematics, MachineConfig, extensions |
| **[ok-cluster](https://github.com/openkubes/ok-cluster)** | Cluster lifecycle — CAPI, CAPK, upgrade, scale |
| **[ok-local](https://github.com/openkubes/ok-local)** | Local development environment |
| **[openkubes](https://github.com/openkubes/openkubes)** | Architecture, docs, vision |

---

## License

Apache 2.0 — see [LICENSE](LICENSE)
