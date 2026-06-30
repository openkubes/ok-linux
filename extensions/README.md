# ok-linux Extensions

Curated Talos extensions for OpenKubes node profiles. This directory governs which extensions ok-linux supports and why.

Extensions add software to a Talos image — kernel modules, system daemons, runtime components. Unlike profiles (declarative, maintenance-free), extensions require ongoing maintenance:

- Upstream security update tracking
- Compatibility testing with each Talos minor version
- Deprecation planning when upstream drops support

This is why extensions are Phase 3 — introduced only after profiles and Image Factory (Phase 1, 2) are stable. See [docs/spec.md](../docs/spec.md) Section 6 and [docs/adr/ADR-006-extensions-phase-3.md](../docs/adr/ADR-006-extensions-phase-3.md).

---

## Acceptance criteria

An extension may be added to ok-linux if it meets ALL of the following:

1. **Available upstream** — exists in the [Siderolabs Extensions catalog](https://github.com/siderolabs/extensions)
2. **Active maintenance** — upstream has had a release or commit in the last 6 months
3. **Security update cadence** — upstream responds to CVEs within 30 days
4. **Justified need** — at least one ok-linux profile explicitly requires it
5. **Tested** — verified on a running cluster before marking stable

---

## Directory structure

```
extensions/<name>/
├── schematic-addition.yaml   # Talos schematic fragment to add to a profile
├── README.md                 # Purpose, compatibility matrix, tested configurations
└── CHANGELOG.md              # Per-extension changelog
```

`schematic-addition.yaml` is a fragment — not a complete schematic. It shows what to add to a profile's `schematic.yaml` under `customization.systemExtensions.officialExtensions`. The profile's own `schematic.yaml` remains the single source of truth that gets submitted to the Talos Image Factory (see [docs/spec.md](../docs/spec.md) Section 5).

---

## Approved extensions

| Extension | Profile | Status | Maintenance owner | Jira |
|---|---|---|---|---|
| [`qemu-guest-agent`](qemu-guest-agent/) | kubevirt | ✅ active | Talos upstream (siderolabs) | [OK-50](https://kubernauts.atlassian.net/browse/OK-50) |
| [`nvidia`](nvidia/) | gpu | 📋 planned | NVIDIA / Talos upstream | [OK-49](https://kubernauts.atlassian.net/browse/OK-49) |

---

## How to propose a new extension

1. Verify it meets all five acceptance criteria above
2. Open a GitHub issue describing the use case and the profile it would extend
3. Once approved, create `extensions/<name>/` following the directory structure above
4. Add the extension's short name to `customization.systemExtensions.officialExtensions` in the relevant profile's `schematic.yaml`
5. Run `make build PROFILE=<name>` to verify the new schematic ID
6. Update this README's "Approved extensions" table

---

## Removing an extension

An extension is removed if:
- Upstream is no longer maintained (no commits/releases for 12+ months)
- A security vulnerability is not patched within 30 days and no mitigation exists
- No active profile uses it anymore

Removal follows the same process: update the profile's `schematic.yaml`, run `make build`, document the change in `CHANGELOG.md`.
