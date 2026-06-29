# ok-linux — Architecture

ok-linux is the Kubernetes Host OS layer of OpenKubes. It provides Talos Linux profiles, Image Factory schematics, and MachineConfig presets — so that [ok-cluster](https://github.com/openkubes/ok-cluster) only needs to say:

```yaml
os:
  distribution: ok-linux
  profile: kubevirt
```

---

## Three-phase evolution

```
Phase 1 — Profiles          Phase 2 — Image Factory     Phase 3 — Extensions
──────────────────          ───────────────────────     ────────────────────
profiles/                   make build/show PROFILE=    extensions/
  kubevirt/       ✓           kubevirt/schematic.yaml ✓   nvidia         (OK-49)
  baremetal/      ✓           baremetal/schematic.yaml ✓  qemu-guest-agent ✓
  edge/           ✓                                        iscsi / mellanox
  gpu/         planned       → ok-linux v0.1.0             ros2-runtime
                               for KubeVirt ✓
```

**Phase 1 (done):** Declarative OS profiles per target environment. Each profile defines Talos version, schematic ID, kernel args, and MachineConfig defaults.

**Phase 2 (done):** `make build PROFILE=kubevirt` submits `schematic.yaml` to `factory.talos.dev`, gets back the schematic ID, and writes it into `profile.yaml`. ok-linux is now the single source of truth for all Talos schematic IDs.

**Phase 3 (planned):** Curated extensions with governance criteria. Extensions are software — they require ongoing maintenance. Profiles are declarative.

---

## Integration with ok-cluster

```
ok-linux              Talos Image Factory       ok-cluster
profile: kubevirt  →  schematic → ID        →   CAPK template
```

ok-cluster references ok-linux profiles instead of raw Talos schematic IDs:

```yaml
# ok-cluster cluster-config.yaml
os:
  distribution: ok-linux
  profile: kubevirt
  schematic_id: ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515
```

The schematic ID is today set manually — in a future release, `render.py` will resolve it automatically from the ok-linux profile (no manual update needed).

---

## Scalability

Today:
```
ok-linux → Talos
```

Tomorrow:
```
ok-linux
├── Talos           (kubevirt, baremetal, edge)
├── Talos FIPS      (compliance environments)
├── Talos Edge      (IoT, ROS2)
└── Talos GPU       (RTX 4000 Ada, first-class profile)
```

ok-cluster remains unchanged — it simply selects a different profile.

---

## Role separation

| Repository | Responsibility |
|---|---|
| **ok-linux** | OS profiles, Image Factory schematics, MachineConfig defaults, extensions |
| **ok-cluster** | Cluster lifecycle — CAPI, CAPK, ClusterClass, upgrade, scale |
| **ok-gitops** | ArgoCD bootstrap, fleet management |
| **ok-apps** | Curated platform applications |
| **openkubes** | Architecture, documentation, vision |

ok-cluster never needs to know which Talos version or schematic ID is in use.
ok-linux is the source of truth.

---

## Current status

| Component | Status | Jira |
|---|---|---|
| profiles/kubevirt | ✅ stable, verified vs ok1-talos | OK-42 |
| profiles/baremetal | 🚧 in progress | OK-43 |
| profiles/edge | 📋 draft | OK-44 |
| profiles/gpu | 📋 planned | — |
| Image Factory + Makefile | ✅ make build/show/verify | OK-45 |
| ok-cluster integration | ✅ schematic_id in cluster-config | OK-46 |
| Versionierung v0.1.0 | ✅ | OK-47 |
| Extension nvidia | 📋 planned | OK-49 |
| Extension qemu-guest-agent | ✅ active in kubevirt profile | OK-50 |

→ See [roadmap.md](roadmap.md) for details.
