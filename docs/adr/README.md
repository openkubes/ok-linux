# Architecture Decision Records (ADR)

This directory contains Architecture Decision Records for ok-linux.

An ADR documents a significant architectural decision: the context that led to it, the decision itself, the rationale, and the consequences. ADRs are immutable once accepted — they record history, not current state.

## What belongs here

- Decisions that affect the overall design of ok-linux
- Decisions that would be hard to reverse or that carry significant trade-offs
- Decisions that future contributors might question without context

## What does NOT belong here

- Implementation details that may change frequently
- Decisions that are obviously correct and require no justification
- Bug fixes or minor improvements

## Status values

| Status | Meaning |
|---|---|
| `Accepted` | Decision is in effect |
| `Superseded by ADR-XXX` | A later decision replaced this one |
| `Deprecated` | No longer relevant |
| `Proposed` | Under discussion, not yet accepted |

## Index

| ADR | Title | Status |
|---|---|---|
| [ADR-001](ADR-001-talos-as-base-os.md) | Talos Linux as the base OS | Accepted |
| [ADR-002](ADR-002-profiles-as-abstraction.md) | Profiles as the primary abstraction | Accepted |
| [ADR-003](ADR-003-gpu-first-class-profile.md) | GPU as a first-class profile | Accepted |
| [ADR-004](ADR-004-schematic-id-static-then-dynamic.md) | Schematic ID resolution — static now, dynamic later | Accepted |
| [ADR-005](ADR-005-schematic-in-profiles-not-image-factory.md) | schematic.yaml lives in profiles/, not image-factory/ | Accepted |
| [ADR-006](ADR-006-extensions-phase-3.md) | Extensions come after Phase 2 | Accepted |
| [ADR-007](ADR-007-archive-naming.md) | archive/ instead of _archive/ | Accepted |
| [ADR-008](ADR-008-distribution-layer-not-fork.md) | ok-linux is a Distribution Layer, not a Fork | Accepted |

## How to add a new ADR

1. Copy `ADR-000-template.md` to `ADR-NNN-short-title.md`
2. Fill in all sections
3. Add an entry to the index above
4. Reference the ADR in `spec.md` Decision Log
5. Submit a pull request
