# ok-linux Roadmap

ok-linux is the Kubernetes Host OS layer of OpenKubes.
It provides Talos Linux profiles, Image Factory schematics, MachineConfig presets, and curated extensions — so that [ok-cluster](https://github.com/openkubes/ok-cluster) only needs to say:

```yaml
os:
  distribution: ok-linux
  profile: kubevirt
```

---

## Phase 1 — Profiles ✅

Declarative OS profiles per target environment. Rein deklarativ, kein laufender Aufwand nach Fertigstellung.

```
profiles/
├── kubevirt/     ✅  Talos VMs under KubeVirt (QEMU/KVM)
├── baremetal/    ✅  Physical servers (Hetzner AX/EX)
├── edge/         ✅  Single-node, IoT, ROS2 (draft)
└── gpu/          📋  GPU nodes (RTX 4000 Ada, first-class profile)
```

Each profile defines:
- Talos version + schematic ID
- Kernel args
- MachineConfig defaults (disk, network, time)
- Active extensions
- Node labels + taints (gpu profile)

Tracked: [OK-41](https://kubernauts.atlassian.net/browse/OK-41) – [OK-44](https://kubernauts.atlassian.net/browse/OK-44)

---

## Phase 2 — Image Factory 📋

Reproducible Talos images via Image Factory schematics. ok-linux becomes the single source of truth for all Talos schematic IDs.

```
profiles/
└── kubevirt/
    ├── profile.yaml       # version, schematic_id, kernel_args
    ├── schematic.yaml     # submitted to Talos Image Factory
    └── machineconfig.yaml # MachineConfig defaults for ok-cluster
```

**Makefile workflow:**

```bash
make show PROFILE=kubevirt
# Profile: kubevirt
# Talos:   v1.9.5
# Extensions: qemu-guest-agent
# Schematic ID: ce4c980...

make build PROFILE=kubevirt
# → submits schematic.yaml to factory.talos.dev
# → writes schematic_id back to profile.yaml
# → outputs image URL
```

ok-cluster resolves `profile: kubevirt` → schematic ID → image URL internally.
No Talos-specific details leak into ok-cluster.

Tracked: [OK-45](https://kubernauts.atlassian.net/browse/OK-45) – [OK-47](https://kubernauts.atlassian.net/browse/OK-47)

---

## Phase 3 — Extensions 📋

Curated Talos extensions with governance and maintenance criteria.

```
extensions/
├── README.md          # Acceptance criteria, maintenance policy
├── nvidia/            # NVIDIA GPU (RTX 4000 Ada)
├── qemu-guest-agent/  # KubeVirt snapshot support
└── ros2/              # Robot Operating System 2 (edge)
```

Extensions are software — they require ongoing updates. Profiles and schematics are declarative. That's why extensions come last.

Tracked: [OK-48](https://kubernauts.atlassian.net/browse/OK-48) – [OK-50](https://kubernauts.atlassian.net/browse/OK-50)

---

## GPU as a first-class profile

`gpu` is a profile, not just an extension. A GPU node is a distinct node type with its own:

```yaml
# profiles/gpu/profile.yaml
talos:
  version: v1.9.5
  schematic_id: <nvidia-schematic>

extensions:
  - nvidia-container-toolkit

machine_config:
  kubelet:
    extraArgs:
      node-labels: "ok-linux/profile=gpu,nvidia.com/gpu=true"
  nodeTaints:
    - "nvidia.com/gpu=true:NoSchedule"
```

This keeps ok-cluster clean: a GPU workload cluster simply requests `profile: gpu`.

---

## Role separation

| Repository | Responsibility |
|---|---|
| **ok-linux** | OS profiles, Image Factory schematics, MachineConfig, extensions |
| **ok-cluster** | Cluster lifecycle — CAPI, CAPK, ClusterClass, upgrade, scale |
| **ok-gitops** | ArgoCD bootstrap, fleet management |
| **ok-apps** | Curated platform applications |

ok-cluster never needs to know which Talos version or schematic ID is in use.
ok-linux is the source of truth.
