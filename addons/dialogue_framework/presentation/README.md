# Presentation Subsystem

**Architecture:** [ADR-014 Product Structure and Presentation](../../../../docs/architecture/dialogue/decisions/014-product-structure-and-presentation.md) · [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md)

This folder is the **Presentation subsystem** of the Dialogue Framework product. It is **not** part of Runtime.

## Purpose

Reusable dialogue presentation technology:

- `IDialoguePresenter` implementations
- Reference HUD scenes (`.tscn`) and presentation resources (`.tres`)
- Typewriter/reveal, tag timing (`#voice`, `#time`), choice/speaker UX
- Optional Ui React adapter paths (Presentation → Ui React only)

## Boundaries

| Presentation may | Presentation must not |
|------------------|----------------------|
| Import `runtime/` and `data/` | Be imported by `runtime/` |
| Use native Godot `Control` nodes | Traverse dialogue graphs or mutate game state |
| Optionally use `addons/ui_react/` | Require Ui React |

## Status

Reference implementations will be migrated from `game/dialogue_demo/` as the Presentation subsystem is populated. Until then, this folder documents the architectural boundary and import rules.

## Related

- [game_presenter.md](../docs/game_presenter.md) — Contract and presentation responsibilities
- [extension_points.md](../docs/extension_points.md) — Runtime extension points
