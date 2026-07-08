# Presentation Subsystem

**Product specification:** [Presentation Product Specification v1](../../../../docs/architecture/dialogue/07-presentation-product-spec.md)  
**Architecture:** [ADR-014](../../../../docs/architecture/dialogue/decisions/014-product-structure-and-presentation.md) · [ADR-015–019](../../../../docs/architecture/dialogue/decisions/015-presentation-product-concepts.md) · [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md)  
**v1 reference scope:** [reference-content-v1.md](reference-content-v1.md)

This folder is the **Presentation subsystem** of the Dialogue Framework product. It is **not** part of Runtime.

## Purpose

Reusable dialogue presentation technology:

- Dialogue HUD **layout scenes** (primary consumer surface)
- **Theme**, **Policy**, and **Input** resources (editor-first customization)
- `IDialoguePresenter` reference implementations (Runtime integration infrastructure)
- Typewriter/reveal, tag timing (`#voice`, `#time`), choice/speaker UX
- Default dialogue UX input (skip, advance, choice navigation)
- Optional Ui React per-control composition (not a separate product path)

## Product concepts

| Concept | Customize by |
|---------|--------------|
| **Layout** | Duplicate layout scene; edit in Godot scene editor |
| **Theme** | Duplicate Theme `.tres`; assign on presenter |
| **Policy** | Duplicate Policy `.tres`; assign on presenter |
| **Input** | Duplicate Input `.tres`; assign on layout |

See [game_presenter.md](../docs/game_presenter.md) for integration and [reference-content-v1.md](reference-content-v1.md) for v1 assets.

## Boundaries

| Presentation may | Presentation must not |
|------------------|----------------------|
| Import `runtime/` and `data/` | Be imported by `runtime/` |
| Use native Godot `Control` nodes | Traverse dialogue graphs or mutate game state |
| Optionally use `addons/ui_react/` per control | Require Ui React |

## Reference assets (current baseline)

See [reference-content-v1.md](reference-content-v1.md) for full v1 scope and target resource model.

### Native baseline (required without Ui React)

| Asset | Path |
|-------|------|
| Native layout | `res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn` |
| Native presenter | `res://addons/dialogue_framework/presentation/native_dialogue_presenter.gd` |

### Ui React composition (optional per control)

| Asset | Path |
|-------|------|
| Ui React layout | `res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn` |
| Ui React presenter | `res://addons/dialogue_framework/presentation/ui_react_dialogue_presenter.gd` |
| Ui React UI states | `res://addons/dialogue_framework/presentation/ui_states/*.tres` |

Layouts may mix native and Ui React controls. Theme, Policy, and Input resources are shared across control mixes when implemented.

## Demo consumption

The dialogue showcase demo (`game/dialogue_demo/`) instances the Ui React reference layout:

- `game/dialogue_demo/scenes/dialogue_demo.tscn` → `ui_react_dialogue_hud.tscn`

Games adopting the **native baseline** should instance `native_dialogue_hud.tscn` without requiring Ui React.

## Testing

Native layout integration coverage: `tests/unit/test_native_presentation_hud_integration.gd`

```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://addons/dialogue_framework/tests/unit -ginclude_subdirs \
  -gselect=test_native_presentation_hud_integration -gexit
```

Full suite: [../README.md](../README.md#testing)

## Related

- [game_presenter.md](../docs/game_presenter.md) — Contract and product guide
- [extension_points.md](../docs/extension_points.md) — Runtime extension points
- [07-presentation-product-spec.md](../../../../docs/architecture/dialogue/07-presentation-product-spec.md) — Frozen product specification v1
