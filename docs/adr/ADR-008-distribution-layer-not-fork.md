# ADR-008: ok-linux is a Distribution Layer, not a Fork

**Date:** 2026-06-29  
**Status:** Accepted  

---

## Context

During the transition from custom kernel to Talos-based profiles (ADR-001), a deeper strategic question emerged: what is ok-linux's relationship to Talos Linux? Two positions were possible:

1. **Fork:** ok-linux maintains its own Talos fork, applying patches for OpenKubes-specific requirements
2. **Distribution layer:** ok-linux configures and extends official Talos releases without modifying Talos itself

This ADR documents that the distribution layer position was consciously chosen — and why forking is considered a last resort.

## Decision

> ok-linux is a distribution layer on top of Talos Linux. ok-linux will not fork Talos. Forking is considered a last resort, triggered only when an upstream contribution path is unavailable and the requirement is critical to OpenKubes.

## Rationale

- **Forking inherits the full maintenance burden.** A Talos fork means owning: kernel CVE patches, Kubernetes version compatibility, containerd updates, secure boot signing, and release cadence. This is a full-time engineering investment that provides no OpenKubes-specific value.
- **Talos already covers all OS-level requirements.** Immutability, API-driven configuration, KubeVirt compatibility, bare-metal provisioning, GPU support via extensions — Talos handles all of this upstream. ok-linux does not need to modify the OS to deliver its value.
- **The extension model is the correct customisation path.** When ok-linux needs OS-level capabilities (nvidia GPU, qemu-guest-agent, iscsi), the Talos Extension catalog provides the mechanism. If a required extension does not exist, the correct path is an upstream contribution to `github.com/siderolabs/extensions`.
- **MachineConfig covers configuration-level customisation.** Anything that is configuration rather than software (kubelet flags, network settings, disk layout) belongs in `machineconfig.yaml` — no OS modification required.
- **Distribution layers scale; forks accumulate debt.** A distribution layer can track Talos releases by updating a version string. A fork requires a rebase against every Talos release — and the diff grows over time.
- **Vendor alignment reduces risk.** Staying on official Talos releases means ok-linux users benefit from Sidero Labs' security response, enterprise support, and community contributions without additional work.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Fork Talos for OpenKubes-specific patches | Full OS maintenance burden; no proportional value; divergence grows over time |
| Maintain a patchset on top of Talos (à la downstream kernel) | Still requires rebasing against every Talos release; complex CI |
| Switch to a more forkable OS (e.g. Flatcar) | Talos is superior for Kubernetes-native use cases; switching would lose Image Factory, MachineConfig API, and Talos community |

## Consequences

**Positive:**
- ok-linux tracks Talos releases with a version string update — no rebase required
- ok-linux users automatically benefit from upstream security fixes
- ok-linux contributors can focus on profiles, schematics, and governance — not OS internals
- Enterprise users can combine ok-linux profiles with official Talos enterprise support

**Negative / trade-offs:**
- ok-linux cannot implement OS-level requirements that Talos upstream refuses to support
- If Talos introduces a breaking change to the Extension API or Image Factory, ok-linux must adapt

**Neutral:**
- If a future requirement genuinely cannot be met through extensions, MachineConfig, or upstream contribution, a new ADR will be raised to reconsider this decision. The decision is not permanent — it is a deliberate default.

## Trigger for revisiting

This ADR should be revisited if:
- A critical OpenKubes requirement cannot be met through Talos extensions or MachineConfig
- Talos upstream becomes unresponsive to security issues for more than 60 days
- A significant portion of the OpenKubes roadmap requires OS-level modifications not supportable via extensions
