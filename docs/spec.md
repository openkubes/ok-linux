# ok-linux Specification

**Version:** 0.1.0  
**Status:** Living Document  
**Maintainer:** Kubernauts / OpenKubes  
**Repository:** [github.com/openkubes/ok-linux](https://github.com/openkubes/ok-linux)  
**Jira Epic:** [OK-37](https://kubernauts.atlassian.net/browse/OK-37)  
**Last updated:** 2026-06-29

---

## Table of Contents

1. [Vision & Positioning](#1-vision--positioning)
2. [Architecture](#2-architecture)
3. [Profile Specification](#3-profile-specification)
4. [Image Factory Contract](#4-image-factory-contract)
5. [Extension Governance](#5-extension-governance)
6. [Integration Contract with ok-cluster](#6-integration-contract-with-ok-cluster)
7. [Versioning Policy](#7-versioning-policy)
8. [Roadmap](#8-roadmap)
9. [Decision Log](#9-decision-log)

---

## 1. Vision & Positioning

### What is ok-linux?

ok-linux is the **Kubernetes Host OS layer** of [OpenKubes](https://github.com/openkubes/openkubes).

It provides:
- **Talos Linux profiles** — declarative OS configurations per target environment
- **Image Factory schematics** — reproducible Talos image definitions submitted to `factory.talos.dev`
- **MachineConfig presets** — default kubelet, network, time, and security settings per profile
- **Curated extensions** — governed Talos extensions for GPU, storage, and virtualisation

### What ok-linux is NOT

ok-linux is **not** a general-purpose Linux distribution. It does not build a custom kernel, manage package repositories, or define a container runtime. These responsibilities belong to Talos Linux upstream.

ok-linux is a **curation and abstraction layer** on top of Talos Linux.

### Positioning within OpenKubes

```
OpenKubes
│
├── ok-local      Local development environment
├── ok-cluster    Cluster lifecycle engine (CAPI, CAPK, ClusterClass)
├── ok-linux      Kubernetes Host OS  ← this repository
├── ok-gitops     GitOps bootstrap and fleet management
├── ok-apps       Curated platform applications
└── openkubes     Architecture, documentation, vision
```

### Design principle

> ok-cluster should never need to know which Talos version or schematic ID is in use.
> ok-linux is the source of truth.

ok-cluster expresses intent:
```yaml
os:
  distribution: ok-linux
  profile: kubevirt
```

ok-linux provides the implementation details.

---

## 2. Architecture

### Three-phase evolution

ok-linux is developed in three phases of increasing complexity:

| Phase | Scope | Status |
|---|---|---|
| **1 — Profiles** | Declarative OS profiles per target environment | ✅ v0.1.0 |
| **2 — Image Factory** | Reproducible Talos images via schematics, `make build/show` | ✅ v0.1.0 |
| **3 — Extensions** | Curated Talos extensions with governance | 📋 planned |

**The key insight:** Profiles and schematics are declarative — they require no ongoing maintenance once defined. Extensions are software — they require security updates, upstream tracking, and compatibility testing. This is why extensions come last.

### Repository structure

```
ok-linux/
├── profiles/                  # Phase 1 — one directory per target environment
│   ├── kubevirt/
│   │   ├── profile.yaml       # Talos version, schematic_id, kernel_args, extensions
│   │   ├── schematic.yaml     # Talos Image Factory input (Phase 2)
│   │   ├── machineconfig.yaml # MachineConfig defaults for ok-cluster (Phase 2)
│   │   └── README.md
│   ├── baremetal/
│   ├── edge/
│   └── gpu/                   # Planned — first-class GPU profile
│
├── extensions/                # Phase 3 — curated Talos extensions
│   ├── README.md              # Governance criteria
│   ├── nvidia/
│   └── qemu-guest-agent/
│
├── docs/
│   ├── spec.md                # This document
│   ├── architecture.md        # Architecture overview
│   └── roadmap.md             # Phase roadmap
│
├── archive/                   # Historical — previous custom kernel/image approach
├── Makefile                   # make build/show/verify/show-all PROFILE=
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

### Role separation

| Repository | Responsibility |
|---|---|
| **ok-linux** | OS profiles, Image Factory schematics, MachineConfig, extensions |
| **ok-cluster** | Cluster lifecycle — CAPI, CAPK, ClusterClass, upgrade, scale, status |
| **ok-gitops** | ArgoCD bootstrap, fleet management |
| **ok-apps** | Curated platform applications |
| **openkubes** | Architecture, documentation, vision |

---

## 3. Profile Specification

### Purpose

A profile is a declarative, versioned description of a Talos Linux configuration for a specific node type or deployment environment. Profiles are the primary artifact of ok-linux Phase 1.

### Profile schema

```yaml
# profiles/<name>/profile.yaml

talos:
  version: string          # Talos release version, e.g. "v1.9.5"
  schematic_id: string     # SHA256 hex from Talos Image Factory
  image: string            # Full image URL, e.g. "https://factory.talos.dev/installer/<id>:v1.9.5"

kernel_args:               # List of kernel boot arguments
  - string

machine_config:            # MachineConfig defaults
  install:
    disk: string           # Install disk path, e.g. "/dev/vda"
    wipe: bool             # Default: false
  network:
    nameservers:           # List of DNS resolvers
      - string
  time:
    servers:               # List of NTP servers
      - string

extensions:                # List of active Talos extensions (short names)
  - string                 # e.g. "qemu-guest-agent", "nvidia-container-toolkit"

notes: string              # Human-readable notes about the profile
```

### Profile naming convention

Profile names are lowercase, hyphen-separated, and describe the **target environment**, not the hardware:

| Profile | Target environment |
|---|---|
| `kubevirt` | Talos VMs under KubeVirt (QEMU/KVM) |
| `baremetal` | Physical servers (Hetzner AX/EX or compatible) |
| `edge` | Single-node, IoT, ROS2, air-gapped |
| `gpu` | GPU-accelerated nodes (first-class profile) |

### Profile stability levels

| Status | Meaning |
|---|---|
| `stable` | Tested against a running cluster, schematic ID verified |
| `in progress` | Profile defined, not yet fully tested |
| `draft` | Placeholder — design intent documented, not deployable |
| `planned` | Not yet created |

### Adding a new profile

1. Create `profiles/<name>/` directory
2. Add `profile.yaml` following the schema above
3. Add `schematic.yaml` (see Section 4)
4. Run `make build PROFILE=<name>` to generate and verify the schematic ID
5. Add `README.md` documenting target environment, constraints, and tested configurations
6. Submit a pull request referencing the relevant Jira story

---

## 4. Image Factory Contract

### Purpose

The Talos Image Factory (`factory.talos.dev`) generates reproducible Talos images from declarative schematics. ok-linux owns all schematics and is the single source of truth for schematic IDs.

No component outside ok-linux should ever hardcode a Talos schematic ID. All schematic IDs must be derived from ok-linux profile definitions.

### Schematic schema

```yaml
# profiles/<name>/schematic.yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/<extension-name>   # zero or more entries
```

The schematic file must not contain comments when submitted to the Image Factory API (comments are stripped automatically by `make build`).

### Makefile interface

```bash
# Show profile summary (version, schematic ID, extensions, kernel args)
make show PROFILE=<name>

# Submit schematic to factory.talos.dev, write ID back to profile.yaml
make build PROFILE=<name>

# Verify schematic_id in profile.yaml matches current schematic.yaml
make verify PROFILE=<name>

# Show summary for all profiles
make show-all
```

### make build behaviour

1. Strips comments from `profiles/<name>/schematic.yaml`
2. POSTs the cleaned YAML to `https://factory.talos.dev/schematics`
3. Extracts the returned `id` field
4. Constructs the image URL: `https://factory.talos.dev/installer/<id>:<talos_version>`
5. Updates `profile.yaml`: sets `talos.schematic_id` and `talos.image`
6. Prints the next step for ok-cluster

### Schematic ID stability

The Talos Image Factory returns a deterministic ID for a given schematic content. The same `schematic.yaml` always produces the same ID. Therefore:

- `schematic_id` in `profile.yaml` is a reproducible artifact, not a secret
- It can be committed to version control
- It can be verified at any time with `make verify PROFILE=<name>`

### Verified schematics (v0.1.0)

| Profile | Schematic ID | Extensions |
|---|---|---|
| `kubevirt` | `ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515` | `siderolabs/qemu-guest-agent` |
| `baremetal` | pending — run `make build PROFILE=baremetal` | none |

---

## 5. Extension Governance

### Purpose

Extensions add software to the Talos image — kernel modules, system daemons, runtime components. Unlike profiles (declarative, maintenance-free), extensions require:
- Upstream security update tracking
- Compatibility testing with each Talos minor version
- Deprecation planning when upstream drops support

This is why Phase 3 (Extensions) comes after Phase 1 and 2 are stable.

### Acceptance criteria

An extension may be added to ok-linux if it meets ALL of the following:

1. **Available upstream** — exists in the [Siderolabs Extensions catalog](https://github.com/siderolabs/extensions)
2. **Active maintenance** — upstream has had a release or commit in the last 6 months
3. **Security update cadence** — upstream responds to CVEs within 30 days
4. **Justified need** — at least one ok-linux profile explicitly requires it
5. **Tested** — verified on a running cluster before marking stable

### Extension directory structure

```
extensions/<name>/
├── schematic-addition.yaml   # Talos schematic fragment to add to a profile
├── README.md                 # Purpose, compatibility matrix, tested configurations
└── CHANGELOG.md              # Per-extension changelog
```

### Approved extensions (v0.1.0)

| Extension | Profile | Status | Jira |
|---|---|---|---|
| `siderolabs/qemu-guest-agent` | kubevirt | ✅ active (embedded in schematic) | OK-50 |
| `siderolabs/nvidia-container-toolkit` | gpu | 📋 planned | OK-49 |

---

## 6. Integration Contract with ok-cluster

### Current state (v0.1.0 — static)

ok-cluster reads the schematic ID from `cluster-config.yaml`:

```yaml
# ok-cluster cluster-config.yaml
os:
  distribution: ok-linux
  profile: kubevirt
  schematic_id: ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515
```

`render.py` resolves `schematic_id` with priority:

```python
"TALOS_SCHEMATIC_ID": (
    cfg.get("os", {}).get("schematic_id") or   # 1. cluster-config.yaml
    os.environ.get("TALOS_SCHEMATIC_ID") or     # 2. environment variable
    "<fallback-id>"                             # 3. hardcoded fallback
),
```

The schematic ID is set manually after running `make build PROFILE=<name>` in ok-linux.

### Future state (dynamic resolution)

In a future release, `render.py` will resolve the schematic ID automatically from ok-linux:

```python
# Planned — no ok-cluster template changes required
schematic_id = fetch_from_ok_linux(
    profile=cfg["os"]["profile"],
    version=cfg["os"].get("version", "latest")
)
```

The `os.schematic_id` field in `cluster-config.yaml` is the **seam** between static and dynamic resolution. The field name and position will not change — only whether it is set manually or automatically.

### Template annotation

The rendered `KubevirtMachineTemplate` carries the schematic ID as an annotation for traceability:

```yaml
metadata:
  annotations:
    openkubes.io/talos-schematic: <schematic_id>
```

This annotation is the audit trail — it records which ok-linux schematic was used to create a given cluster.

---

## 7. Versioning Policy

ok-linux follows [Semantic Versioning](https://semver.org/):

| Increment | Trigger |
|---|---|
| **Patch** `v1.0.x` | Talos version bump within a profile, no schema changes |
| **Minor** `v1.x.0` | New profile added, new extension added |
| **Major** `vX.0.0` | Breaking change to profile schema, extension API, or Makefile interface |

### Release process

1. Update `CHANGELOG.md` with release notes
2. Run `make verify PROFILE=<name>` for all stable profiles
3. Commit: `git commit -m "chore(release): vX.Y.Z"`
4. Tag: `git tag -a vX.Y.Z -m "ok-linux vX.Y.Z — <summary>"`
5. Push tag: `git push origin vX.Y.Z`
6. Update `schematic_id` in ok-cluster `cluster-config.yaml` if changed

### Current releases

| Version | Date | Highlights |
|---|---|---|
| `v0.1.0` | 2026-06-29 | Phase 1 profiles (kubevirt, baremetal, edge) + Phase 2 Image Factory + Makefile |

---

## 8. Roadmap

### Phase 1 — Profiles ✅ (v0.1.0)

- [x] OK-41: Repository structure, archive old approach
- [x] OK-42: Profile `kubevirt` — stable, verified vs ok1-talos cluster
- [x] OK-43: Profile `baremetal` — Hetzner AX/EX provisioning documented
- [x] OK-44: Profile `edge` — draft, use cases documented

### Phase 2 — Image Factory ✅ (v0.1.0)

- [x] OK-45: `schematic.yaml` per profile, `make build/show/verify PROFILE=`
- [x] OK-46: ok-cluster reads `schematic_id` from `cluster-config.yaml`
- [x] OK-47: Versioning, `CHANGELOG.md`, `v0.1.0` tag

### Phase 2 — Continued 📋

- [ ] OK-42 revisit: `machineconfig.yaml` per profile
- [ ] profiles/gpu: First-class GPU profile (RTX 4000 Ada, GEX44)
- [ ] Dynamic schematic ID resolution in `render.py`

### Phase 3 — Extensions 📋

- [ ] OK-48: Extension governance structure and acceptance criteria
- [x] OK-50: Extension `qemu-guest-agent` — active in kubevirt schematic
- [ ] OK-49: Extension `nvidia` — GPU support (RTX 4000 Ada)

### Long-term

- Talos FIPS profile (compliance environments)
- Talos Edge profile (ARM64, air-gapped)
- ok-linux as input to ok-gitops (automatic OS upgrades via GitOps)

---

## 9. Decision Log

Decisions are recorded here permanently. They explain *why* the system is built the way it is, so future contributors understand the reasoning without having to recover it from git history.

---

### DEC-001: Talos Linux as the base OS

**Date:** 2026-06  
**Decision:** ok-linux builds on Talos Linux rather than maintaining a custom kernel.  
**Context:** The initial ok-linux approach (archived in `archive/`) included a custom kernel config, PXE boot scripts, and a Cloud-Init image pipeline. This was replaced.  
**Rationale:**
- Talos is immutable, API-driven, and purpose-built for Kubernetes — exactly what ok-linux needs
- The custom kernel approach required continuous maintenance (patches, security updates, build pipelines)
- Talos Image Factory provides a reproducible, API-driven way to create images — better than a custom build.sh
- ok-linux adds value through curation and abstraction, not through reimplementing what Talos already does well

**Consequence:** ok-linux is a Talos distribution, not a Linux distribution.

---

### DEC-002: Profiles as the primary abstraction

**Date:** 2026-06  
**Decision:** The primary abstraction in ok-linux is a "profile" — a named, declarative OS configuration for a target environment.  
**Context:** Alternatives considered: (a) single global config, (b) per-cluster config, (c) profiles.  
**Rationale:**
- A single global config cannot express the difference between a KubeVirt VM (virtio disk, serial console) and a bare-metal server (NVMe, iPXE boot)
- Per-cluster config duplicates OS configuration across clusters and makes updates error-prone
- Profiles are the right granularity: they capture what's different about a node *type*, not a specific cluster
- Profiles are reusable — multiple clusters can reference the same profile

**Consequence:** ok-cluster references `profile: kubevirt`, not a specific Talos version or schematic ID.

---

### DEC-003: gpu as a first-class profile, not just an extension

**Date:** 2026-06 (GPT architectural review)  
**Decision:** GPU nodes get their own profile (`profiles/gpu/`) rather than being modeled as an extension on top of `baremetal/`.  
**Context:** Initial idea was: baremetal profile + nvidia extension = GPU node.  
**Rationale:**
- A GPU node is a distinct node type with its own kernel args, runtime config, node labels, and taints
- Extensions add software (nvidia-container-toolkit); profiles define the complete node identity
- ok-cluster can express `profile: gpu` cleanly — much clearer than `profile: baremetal + extensions: [nvidia]`
- Future GPU profiles (Jetson, AMD ROCm) are natural additions alongside `gpu/`, not variants of `baremetal/`

**Consequence:** `profiles/gpu/` is planned as a first-class profile targeting the GEX44 + RTX 4000 Ada node (ok-gpu).

---

### DEC-004: Schematic ID resolution — static now, dynamic later

**Date:** 2026-06  
**Decision:** The schematic ID is set manually in `cluster-config.yaml` today. Dynamic resolution from ok-linux is planned but deferred.  
**Context:** The goal is for ok-cluster to reference only `os.profile: kubevirt` without knowing the schematic ID. But ok-cluster's `render.py` needs the ID to render the `KubevirtMachineTemplate`.  
**Rationale:**
- Dynamic resolution requires ok-cluster to fetch from ok-linux at render time — adds complexity and a network dependency
- Static is safe, reproducible, and sufficient for v0.1.0
- The `os.schematic_id` field in `cluster-config.yaml` is the seam — today set manually, tomorrow resolved automatically. The field name will not change.
- `render.py` already supports the priority chain: `cluster-config → env → fallback`

**Consequence:** After running `make build PROFILE=kubevirt` in ok-linux, the operator copies the new schematic ID into `cluster-config.yaml`. This is a deliberate, explicit step.

---

### DEC-005: schematic.yaml lives in profiles/, not image-factory/

**Date:** 2026-06  
**Decision:** `schematic.yaml` lives inside `profiles/<name>/` rather than a separate top-level `image-factory/` directory.  
**Context:** GPT suggested `image-factory/kubevirt/schematic.yaml`. Implemented as `profiles/kubevirt/schematic.yaml`.  
**Rationale:**
- A profile is the complete description of a node type — keeping `profile.yaml` and `schematic.yaml` together is cohesive
- `profile.yaml` references the schematic ID; `schematic.yaml` defines what generates it — they belong together
- A separate `image-factory/` directory creates a split that mirrors the internal implementation (submit → get ID) rather than the user-facing abstraction (this is the kubevirt profile)
- `make build PROFILE=kubevirt` makes the relationship explicit without requiring the user to navigate two directories

**Consequence:** Each profile directory is self-contained. `profiles/kubevirt/` holds everything needed to understand and reproduce the kubevirt OS image.

---

### DEC-006: Extensions come after Phase 2

**Date:** 2026-06 (GPT architectural review, adopted)  
**Decision:** Extension governance and implementation are Phase 3 — after profiles and Image Factory are stable.  
**Rationale:**
- Profiles and schematics are declarative — they require no ongoing maintenance once defined
- Extensions are software — they require security update tracking, Talos version compatibility testing, and deprecation planning
- Starting with extensions would create maintenance obligations before the foundation is stable
- The qemu-guest-agent extension is already active (embedded in the kubevirt schematic) — this is the correct model: extensions live in schematics, not as separate artifacts, until Phase 3 defines the extension directory structure

**Consequence:** Phase 3 begins after `v0.1.0` is proven in production. First extension to formalise: `nvidia` for ok-gpu.

---

### DEC-007: archive/ instead of _archive/

**Date:** 2026-06  
**Decision:** The historical custom kernel/image approach is stored in `archive/` (not `_archive/`).  
**Rationale:** `_archive/` is a convention for "hidden from tooling" (similar to `_build/`, `_site/`). `archive/` is a standard English word that communicates intent clearly without implying the directory should be ignored. Git history preserves the full rename.  
**Consequence:** `archive/` is present in the repository but not referenced by any Makefile target or documentation.

---

*This specification is a living document. Decisions are added as they are made. Sections are updated with each release.*
