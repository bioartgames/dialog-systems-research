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

## Reference assets

### Native Godot path (no Ui React)

| Asset | Path |
|-------|------|
| Native presenter | `res://addons/dialogue_framework/presentation/native_dialogue_presenter.gd` |
| Native HUD scene | `res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn` |

### Ui React path (optional)

| Asset | Path |
|-------|------|
| Ui React presenter | `res://addons/dialogue_framework/presentation/ui_react_dialogue_presenter.gd` |
| Ui React HUD scene | `res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn` |
| Ui React UI states | `res://addons/dialogue_framework/presentation/ui_states/*.tres` |

## Demo consumption

The dialogue showcase demo (`game/dialogue_demo/`) consumes the **Ui React reference HUD**:

- `game/dialogue_demo/scenes/dialogue_demo.tscn` instances `res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn`
- `game/dialogue_demo/scripts/showcase_orchestrator.gd` expects `$DialogueHUD/Presenter` as a `UiReactDialoguePresenter`

Games adopting the **native Godot baseline** should instance `native_dialogue_hud.tscn` (or wire `native_dialogue_presenter.gd` into a custom HUD) without requiring Ui React.

## Related

- [game_presenter.md](../docs/game_presenter.md) — Contract and presentation responsibilities
- [extension_points.md](../docs/extension_points.md) — Runtime extension points
