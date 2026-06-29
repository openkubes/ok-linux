# ok-linux Specification

**Version:** 0.1.1  
**Status:** Living Document  
**Maintainer:** Kubernauts / OpenKubes  
**Repository:** [github.com/openkubes/ok-linux](https://github.com/openkubes/ok-linux)  
**Jira Epic:** [OK-37](https://kubernauts.atlassian.net/browse/OK-37)  
**Last updated:** 2026-06-29

---

## Table of Contents

1. [Principles](#1-principles)
2. [Vision & Positioning](#2-vision--positioning)
3. [Architecture](#3-architecture)
4. [Profile Specification](#4-profile-specification)
5. [Image Factory Contract](#5-image-factory-contract)
6. [Extension Governance](#6-extension-governance)
7. [Integration Contract with ok-cluster](#7-integration-contract-with-ok-cluster)
8. [Versioning Policy](#8-versioning-policy)
9. [Roadmap](#9-roadmap)
10. [Decision Log](#10-decision-log)

---

## 1. Principles

These principles govern every design decision in ok-linux. When in doubt, return to them.

**1. Upstream first.**
ok-linux follows Talos Linux upstream whenever possible. Diverging from upstream is considered a last resort. Extensions, Image Factory schematics, and MachineConfig presets are always preferred over upstream forks.

**2. Declarative over imperative.**
Profiles describe desired state. They never execute installation logic. A profile is a YAML file — not a script.

**3. Minimal opinionation.**
Only add defaults that benefit every OpenKubes user. Cluster-specific or organisation-specific configuration belongs in ok-cluster or ok-gitops, not in ok-linux profiles.

**4. Reproducible.**
Every image must be reproducible from Git. `make build PROFILE=<name>` submitted to the same schematic always returns the same schematic ID. No manual steps, no local state.

**5. Immutable.**
No mutable OS configuration after deployment. Talos is API-driven and immutable by design. ok-linux profiles embrace this — they define the image, not a post-install script.

**6. Source of truth.**
ok-linux is the single source of truth for all Talos schematic IDs. No component outside ok-linux should hardcode a Talos schematic ID.

---

## 2. Vision & Positioning

### What is ok-linux?

ok-linux is the **Kubernetes Host OS layer** of [OpenKubes](https://github.com/openkubes/openkubes).

It provides:
- **Talos Linux profiles** — declarative OS configurations per target environment
- **Image Factory schematics** — reproducible Talos image definitions submitted to `factory.talos.dev`
- **MachineConfig presets** — default kubelet, network, time, and security settings per profile
- **Curated extensions** — governed Talos extensions for GPU, storage, and virtualisation

### What ok-linux is NOT

ok-linux is **not** a general-purpose Linux distribution. It does not build a custom kernel, manage package repositories, or define a container runtime. These responsibilities belong to Talos Linux upstream.

ok-linux is a **distribution layer** on top of Talos Linux — not a fork. See [DEC-008](#dec-008-ok-linux-is-a-distribution-layer-not-a-fork).

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

### Core design principle

> ok-cluster expresses intent. ok-linux is the source of truth.

ok-cluster says:
```yaml
os:
  distribution: ok-linux
  profile: kubevirt
```

ok-linux provides the implementation: Talos version, schematic ID, kernel args, MachineConfig defaults.

---

## 3. Architecture

### Source of truth chain

Every running cluster can be traced back to a single Git commit in ok-linux:

```
Git (ok-linux)
      │
      ▼
profile.yaml          ← Talos version, schematic_id, kernel_args
      │
      ▼
schematic.yaml        ← Extensions submitted to Image Factory
      │
      ▼
Talos Image Factory   ← factory.talos.dev
      │
      ▼
schematic ID          ← deterministic hash of schematic content
      │
      ▼
ok-cluster            ← cluster-config.yaml os.schematic_id
      │
      ▼
CAPK template         ← KubevirtMachineTemplate with image URL
      │
      ▼
Running cluster       ← Talos nodes booting the verified image
```

Git is the root of this chain. Every step is reproducible from source.

### Three-phase evolution

ok-linux is developed in three phases of increasing complexity:

| Phase | Scope | Status |
|---|---|---|
| **1 — Profiles** | Declarative OS profiles per target environment | ✅ v0.1.0 |
| **2 — Image Factory** | Reproducible Talos images via schematics, `make build/show` | ✅ v0.1.0 |
| **3 — Extensions** | Curated Talos extensions with governance | 📋 planned |

**The key insight:** Profiles and schematics are declarative — they require no ongoing maintenance once defined. Extensions are software — they require security updates, upstream tracking, and compatibility testing. This is why extensions come last.

### Three core artifacts per profile

Each profile consists of three equal artifacts:

```
profiles/<name>/
├── profile.yaml        # Identity: Talos version, schematic_id, kernel_args, extensions list
├── schematic.yaml      # Image: submitted to factory.talos.dev, generates schematic_id
├── machineconfig.yaml  # Defaults: kubelet, network, time, security, disk layout
└── README.md           # Documentation: target environment, constraints, tested configs
```

These three artifacts are equally important:
- `profile.yaml` is the **identity** — what this profile is
- `schematic.yaml` is the **image** — what software runs on it
- `machineconfig.yaml` is the **defaults** — how it is configured

### Repository structure

```
ok-linux/
├── profiles/
│   ├── kubevirt/          ✅ stable
│   ├── baremetal/         🚧 in progress
│   ├── edge/              📋 draft
│   └── gpu/               📋 planned (first-class profile)
│
├── extensions/            📋 Phase 3
│   ├── README.md
│   ├── nvidia/
│   └── qemu-guest-agent/
│
├── docs/
│   ├── spec.md            ← this document
│   ├── architecture.md
│   └── roadmap.md
│
├── archive/               historical — previous custom kernel/image approach
├── Makefile
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

This table is load-bearing. When a new feature is proposed, the first question is: which repository owns it?

---

## 4. Profile Specification

### Purpose

A profile is a declarative, versioned description of a Talos Linux configuration for a specific node type or deployment environment.

### Profile schema

```yaml
# profiles/<name>/profile.yaml

talos:
  version: string          # Talos release version, e.g. "v1.9.5"
  schematic_id: string     # SHA256 hex from Talos Image Factory
  image: string            # Full image URL

kernel_args:               # List of kernel boot arguments
  - string

machine_config:            # MachineConfig defaults
  install:
    disk: string           # Install disk path, e.g. "/dev/vda"
    wipe: bool             # Default: false
  network:
    nameservers:
      - string
  time:
    servers:
      - string

extensions:                # Active Talos extensions (informational — source of truth is schematic.yaml)
  - string

notes: string              # Human-readable notes
```

### Profile naming convention

Profile names are lowercase, hyphen-separated, and describe the **target environment**, not the hardware:

| Profile | Target environment | Status |
|---|---|---|
| `kubevirt` | Talos VMs under KubeVirt (QEMU/KVM) | ✅ stable |
| `baremetal` | Physical servers (Hetzner AX/EX or compatible) | 🚧 in progress |
| `edge` | Single-node, IoT, ROS2, air-gapped | 📋 draft |
| `gpu` | GPU-accelerated nodes (RTX 4000 Ada, first-class) | 📋 planned |

### Future: profile versioning

As profiles mature, explicit version pinning will allow parallel profile versions:

```yaml
# Planned — not yet implemented
os:
  distribution: ok-linux
  profile: kubevirt
  profile_version: v1      # or kubevirt@v1
```

This enables enterprise users to pin to a stable profile version while newer versions are developed in parallel. Not required for v0.1.0 — introduced when a profile has its first breaking change.

### Profile stability levels

| Status | Meaning |
|---|---|
| `stable` | Tested against a running cluster, schematic ID verified |
| `in progress` | Profile defined, not yet fully tested |
| `draft` | Design intent documented, not deployable |
| `planned` | Not yet created |

---

## 5. Image Factory Contract

### Purpose

The Talos Image Factory (`factory.talos.dev`) generates reproducible Talos images from declarative schematics. ok-linux owns all schematics and is the single source of truth for schematic IDs.

No component outside ok-linux should ever hardcode a Talos schematic ID.

### Schematic schema

```yaml
# profiles/<name>/schematic.yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/<extension-name>   # zero or more entries
```

### Makefile interface

```bash
make show PROFILE=<name>     # Profile summary: version, schematic ID, extensions, kernel args
make build PROFILE=<name>    # Submit schematic → get ID → update profile.yaml
make verify PROFILE=<name>   # Check schematic_id matches current schematic.yaml
make show-all                # Summary for all profiles
```

### make build behaviour

1. Strips comments from `profiles/<name>/schematic.yaml`
2. POSTs to `https://factory.talos.dev/schematics`
3. Extracts the returned `id`
4. Constructs: `https://factory.talos.dev/installer/<id>:<talos_version>`
5. Updates `profile.yaml`: `talos.schematic_id` and `talos.image`
6. Prints next step for ok-cluster

### Verified schematics (v0.1.0)

| Profile | Schematic ID | Extensions |
|---|---|---|
| `kubevirt` | `ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515` | `siderolabs/qemu-guest-agent` |
| `baremetal` | pending — run `make build PROFILE=baremetal` | none |

---

## 6. Extension Governance

### Purpose

Extensions add software to the Talos image. Unlike profiles (declarative, maintenance-free), extensions require upstream security update tracking, compatibility testing, and deprecation planning.

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
├── schematic-addition.yaml   # Talos schematic fragment
├── README.md                 # Purpose, compatibility matrix, tested configurations
└── CHANGELOG.md
```

### Approved extensions (v0.1.0)

| Extension | Profile | Status | Jira |
|---|---|---|---|
| `siderolabs/qemu-guest-agent` | kubevirt | ✅ active (embedded in schematic) | OK-50 |
| `siderolabs/nvidia-container-toolkit` | gpu | 📋 planned | OK-49 |

---

## 7. Integration Contract with ok-cluster

### Current state (v0.1.0 — static)

ok-cluster reads the schematic ID from `cluster-config.yaml`:

```yaml
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

### Future state (dynamic resolution)

In a future release, `render.py` will resolve the schematic ID automatically from ok-linux. The `os.schematic_id` field is the **seam** — today set manually, tomorrow resolved automatically. The field name will not change.

### Template annotation

The rendered `KubevirtMachineTemplate` carries the schematic ID as an audit annotation:

```yaml
metadata:
  annotations:
    openkubes.io/talos-schematic: <schematic_id>
```

---

## 8. Versioning Policy

ok-linux follows [Semantic Versioning](https://semver.org/):

| Increment | Trigger |
|---|---|
| **Patch** `v1.0.x` | Talos version bump, no schema changes |
| **Minor** `v1.x.0` | New profile or extension added |
| **Major** `vX.0.0` | Breaking change to profile schema, extension API, or Makefile interface |

### Current releases

| Version | Date | Highlights |
|---|---|---|
| `v0.1.0` | 2026-06-29 | Phase 1 profiles (kubevirt, baremetal, edge) + Phase 2 Image Factory + Makefile |

---

## 9. Roadmap

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

- [ ] `machineconfig.yaml` per profile (Phase 2 revisit)
- [ ] `profiles/gpu/` — first-class GPU profile (RTX 4000 Ada, GEX44)
- [ ] Dynamic schematic ID resolution in `render.py`

### Phase 3 — Extensions 📋

- [ ] OK-48: Extension governance structure
- [x] OK-50: `qemu-guest-agent` — active in kubevirt schematic
- [ ] OK-49: `nvidia` — GPU support (RTX 4000 Ada)

---

## 10. Decision Log

Decisions are recorded here permanently. They explain *why* the system is built the way it is.

---

### DEC-001: Talos Linux as the base OS

**Date:** 2026-06  
**Decision:** ok-linux builds on Talos Linux rather than maintaining a custom kernel.  
**Context:** The initial approach (archived in `archive/`) included a custom kernel config, PXE boot scripts, and a Cloud-Init image pipeline.  
**Rationale:**
- Talos is immutable, API-driven, and purpose-built for Kubernetes
- The custom kernel approach required continuous maintenance
- Talos Image Factory provides a reproducible, API-driven image pipeline
- ok-linux adds value through curation and abstraction, not reimplementation

**Consequence:** ok-linux is a Talos distribution, not a Linux distribution.

---

### DEC-002: Profiles as the primary abstraction

**Date:** 2026-06  
**Decision:** The primary abstraction is a "profile" — a named, declarative OS configuration for a target environment.  
**Rationale:**
- A single global config cannot express KubeVirt VM vs bare-metal differences
- Per-cluster config duplicates OS configuration and makes updates error-prone
- Profiles capture what's different about a node *type*, not a specific cluster
- Multiple clusters can reference the same profile

**Consequence:** ok-cluster references `profile: kubevirt`, not a Talos version or schematic ID.

---

### DEC-003: gpu as a first-class profile, not just an extension

**Date:** 2026-06 (GPT architectural review)  
**Decision:** GPU nodes get their own profile (`profiles/gpu/`) rather than being modeled as an extension on `baremetal/`.  
**Rationale:**
- A GPU node has its own kernel args, runtime config, node labels, and taints — it is a distinct node type
- Extensions add software; profiles define node identity
- Future GPU types (AMD ROCm, Jetson, Intel GPU) are natural additions alongside `gpu/`, not variants of `baremetal/`

**Consequence:** `profiles/gpu/` is a first-class profile targeting GEX44 + RTX 4000 Ada (ok-gpu).

---

### DEC-004: Schematic ID resolution — static now, dynamic later

**Date:** 2026-06  
**Decision:** The schematic ID is set manually in `cluster-config.yaml` today. Dynamic resolution is planned but deferred.  
**Rationale:**
- Dynamic resolution adds complexity and a network dependency at render time
- Static is safe, reproducible, and sufficient for v0.1.0
- The `os.schematic_id` field is the seam — today manual, tomorrow automatic
- `render.py` already supports the priority chain: config → env → fallback

**Consequence:** After `make build PROFILE=kubevirt`, the operator copies the schematic ID into `cluster-config.yaml`. This is a deliberate, explicit step.

---

### DEC-005: schematic.yaml lives in profiles/, not image-factory/

**Date:** 2026-06  
**Decision:** `schematic.yaml` lives inside `profiles/<name>/` rather than a separate `image-factory/` directory.  
**Rationale:**
- A profile is the complete description of a node type — `profile.yaml` and `schematic.yaml` belong together
- A separate `image-factory/` directory mirrors internal implementation rather than the user-facing abstraction
- `make build PROFILE=kubevirt` makes the relationship explicit

**Consequence:** Each profile directory is self-contained.

---

### DEC-006: Extensions come after Phase 2

**Date:** 2026-06 (GPT architectural review)  
**Decision:** Extension governance is Phase 3 — after profiles and Image Factory are stable.  
**Rationale:**
- Profiles and schematics are declarative — maintenance-free once defined
- Extensions are software — require security update tracking and compatibility testing
- The `qemu-guest-agent` extension is already active (embedded in the kubevirt schematic) — this is the correct model: extensions live in schematics until Phase 3 formalises the extension directory structure

**Consequence:** Phase 3 begins after `v0.1.0` is proven in production.

---

### DEC-007: archive/ instead of _archive/

**Date:** 2026-06  
**Decision:** Historical files are stored in `archive/`, not `_archive/`.  
**Rationale:** `_archive/` implies "hidden from tooling". `archive/` communicates intent clearly as a standard English word.  
**Consequence:** `archive/` is present but not referenced by any Makefile target or documentation.

---

### DEC-008: ok-linux is a Distribution Layer, not a Fork

**Date:** 2026-06  
**Decision:** ok-linux will never fork Talos Linux. Forking is considered a last resort.  
**Context:** During the transition from the custom kernel approach to Talos-based profiles, a strategic choice was made: diverge from Talos (fork) or extend it (distribution layer). ok-linux is explicitly the latter.  
**Rationale:**
- Forking Talos means inheriting its full maintenance burden: kernel patches, security backports, Kubernetes compatibility, and release cadence
- The Talos upstream already handles everything ok-linux needs at the OS level
- ok-linux's value is in *selecting* and *configuring* the right Talos image for each environment — not in *modifying* Talos itself
- Extensions, Image Factory schematics, and MachineConfig presets provide all the customisation needed without diverging from upstream
- If Talos cannot satisfy a requirement, the correct path is to contribute upstream or propose an extension — not to fork

**Consequence:** ok-linux profiles will always reference official Talos images from `factory.talos.dev`. Any customisation goes through the official Extension catalog. If a future requirement cannot be met this way, it triggers a new decision — not a silent fork.

---

*This specification is a living document. Decisions are added as they are made. Sections are updated with each release.*
