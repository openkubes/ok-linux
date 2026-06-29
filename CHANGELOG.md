# Changelog

All notable changes to ok-linux are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [v0.1.0] — 2026-06-29

Initial release of ok-linux — the Kubernetes Host OS layer of OpenKubes.

### Added

**Phase 1 — Profiles**
- `profiles/kubevirt/profile.yaml` — Talos v1.9.5 for KubeVirt VMs (QEMU/KVM)
- `profiles/kubevirt/schematic.yaml` — Image Factory schematic with `qemu-guest-agent`
- `profiles/kubevirt/README.md` — target environment, CAPK integration, known constraints
- `profiles/baremetal/profile.yaml` — Talos v1.9.5 for Hetzner AX/EX bare metal
- `profiles/baremetal/schematic.yaml` — base Image Factory schematic
- `profiles/baremetal/README.md` — Hetzner provisioning, network topology, disk paths
- `profiles/edge/profile.yaml` — placeholder for single-node, IoT, ROS2 deployments
- `profiles/edge/README.md` — use cases, open questions, potential extensions
- `CONTRIBUTING.md` — guide for contributing new profiles
- `docs/roadmap.md` — Phase 1–3 roadmap, gpu as first-class profile, role separation

**Phase 2 — Image Factory**
- `Makefile` with `make show/build/verify/show-all PROFILE=` targets
- `make build PROFILE=kubevirt` submits schematic to `factory.talos.dev`, writes ID back to `profile.yaml`
- `make verify PROFILE=kubevirt` checks schematic_id consistency
- Schematic ID `ce4c980...` verified against running `ok1-talos` cluster

### Architecture

ok-linux is the single source of truth for Talos schematic IDs.
[ok-cluster](https://github.com/openkubes/ok-cluster) references profiles via:

```yaml
os:
  distribution: ok-linux
  profile: kubevirt
  schematic_id: ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515
```

### Archived

Previous custom kernel/image approach moved to `archive/` (historical reference only).

---

## Upcoming

- `v0.2.0` — profiles/gpu/ (RTX 4000 Ada, first-class profile, OK-49)
- `v1.0.0` — stable profile set, dynamic schematic_id resolution in ok-cluster
