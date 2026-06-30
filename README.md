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
>
> **This is not aspirational — it is how ok-cluster actually works today.** ok-cluster's `render.py` reads `profile.yaml` directly from a sibling ok-linux checkout to resolve the Talos version and schematic ID. See [Integration with ok-cluster](#integration-with-ok-cluster) below.

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
│   ├── README.md      # Governance: acceptance criteria, approval process
│   ├── nvidia/         📋 planned — blocked on profiles/gpu/
│   └── qemu-guest-agent/  ✅ active, embedded in kubevirt schematic
│
├── docs/
│   ├── spec.md         # Full specification — principles, contracts, decision log
│   ├── architecture.md
│   └── adr/            # Architecture Decision Records (ADR-001 – ADR-008)
│
├── archive/           # Previous custom kernel/image approach (historical)
└── Makefile
```

---

## Profiles

Each profile is a declarative YAML describing the complete OS configuration for a node type:

| Profile | Target | Status |
|---|---|---|
| `kubevirt` | Talos VMs under KubeVirt | ✅ stable — verified against running cluster |
| `baremetal` | Hetzner AX/EX bare metal | 🚧 in progress |
| `edge` | IoT / single-node / ROS2 | 📋 draft |
| `gpu` | GPU nodes (RTX 4000 Ada) | 📋 planned |

Each profile contains three equal core artifacts:

```
profiles/kubevirt/
├── profile.yaml        # Identity: Talos version, schematic ID, kernel args, extensions
├── schematic.yaml      # Image: submitted to Talos Image Factory
├── machineconfig.yaml  # Defaults: disk, network, time, resource sizing
└── README.md
```

---

## Integration with ok-cluster

ok-cluster does not hardcode Talos versions or schematic IDs. It reads them directly from this repository.

```
ok-linux/profiles/kubevirt/profile.yaml
        ↓  (talos.version, talos.schematic_id)
ok-cluster's render.py  reads this file from a sibling checkout
        ↓
ok-cluster's cluster-config.yaml   os.profile: kubevirt, os.schematic_id: <resolved>
        ↓
Running cluster
```

This requires `ok-linux` and `ok-cluster` to be sibling directories:

```
~/your-workspace/
├── ok-linux/      ← this repo
└── ok-cluster/    ← github.com/openkubes/ok-cluster
```

If `ok-linux` cannot be found, ok-cluster falls back to hardcoded defaults and prints a warning — see [ok-cluster's README](https://github.com/openkubes/ok-cluster#os-layer-integration).

**Resolution model (today: static, future: dynamic)** — per [ADR-004](docs/adr/ADR-004-schematic-id-static-then-dynamic.md), ok-cluster currently reads `profile.yaml` from disk. A future version may resolve this from a Git ref or API instead — the `os:` field shape in `cluster-config.yaml` will not change either way.

---

## Verified end-to-end

The kubevirt profile's schematic ID (`ce4c980...`) has been verified twice against fresh `make new && make bootstrap` runs on the `ok1-talos` cluster — not just against the original, manually-created cluster. ok-linux is the actual source of truth ok-cluster reads from, not just documentation describing an intended architecture.

---

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| **1 — Profiles** | Declarative OS profiles per environment | ✅ done |
| **2 — Image Factory** | Reproducible images, `make build/show/verify PROFILE=` | ✅ done |
| **3 — Extensions** | Curated extensions with governance | 🚧 governance done, nvidia planned |

→ See [docs/roadmap.md](docs/roadmap.md) for details.

---

## Specification & Architecture Decisions

- [docs/spec.md](docs/spec.md) — full specification: principles, profile schema, Image Factory contract, extension governance, integration contract, versioning policy
- [docs/adr/](docs/adr/) — Architecture Decision Records (ADR-001 through ADR-008): why Talos, why profiles, why GPU is first-class, why ok-linux is a distribution layer and not a Talos fork

---

## Role separation

| Repository | Responsibility |
|---|---|
| **ok-linux** | OS profiles, schematics, MachineConfig, extensions |
| **[ok-cluster](https://github.com/openkubes/ok-cluster)** | Cluster lifecycle — CAPI, CAPK, upgrade, scale |
| **[ok-local](https://github.com/openkubes/ok-local)** | Local development environment |
| **[openkubes](https://github.com/openkubes/openkubes)** | Architecture, docs, vision |

> ok-cluster expresses intent. ok-linux is the source of truth.

---

## License

Apache 2.0 — see [LICENSE](LICENSE)
