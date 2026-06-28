# Contributing to ok-linux

Thank you for contributing to ok-linux — the Kubernetes Host OS layer of OpenKubes.

---

## How to contribute a new profile

A profile is a declarative YAML file describing a Talos Linux configuration for a specific target environment.

### 1. Create the profile directory

```bash
mkdir -p profiles/<name>
```

### 2. Create `profile.yaml`

Use an existing profile as template (e.g. `profiles/kubevirt/profile.yaml`).

Required fields:

```yaml
talos:
  version: vX.Y.Z              # Talos release version
  schematic_id: <hash>         # From Talos Image Factory
  image: factory.talos.dev/... # Full image URL

kernel_args: []                # List of kernel arguments
machine_config:                # MachineConfig defaults
  install:
    disk: /dev/...
extensions: []                 # Active Talos extensions
notes: |                       # Human-readable notes
```

### 3. Create `README.md`

Document the target environment, assumptions, and any provider-specific notes.

### 4. Open a Pull Request

- Title: `profiles/<name>: add initial profile`
- Reference the related Jira ticket if applicable
- Profiles should be tested against a real cluster before marking stable

---

## How to propose a new extension (Phase 3)

Extensions require ongoing maintenance. Before proposing one:

- Verify it is available in the [Talos Extension catalog](https://github.com/siderolabs/extensions)
- Confirm upstream is actively maintained
- Assess security update cadence

Open a GitHub issue first to discuss before implementing.

---

## Versioning

ok-linux follows [semantic versioning](https://semver.org/) for profile sets:

- **Patch** (v1.0.x): Talos version bump within a profile, no breaking changes
- **Minor** (v1.x.0): New profile added
- **Major** (vX.0.0): Breaking change to profile schema or extension API

---

## Questions?

Open an issue or join the [Kubernauts community](https://kubernauts.io).
