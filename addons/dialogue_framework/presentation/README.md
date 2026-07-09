# Presentation Subsystem

**Product specification:** [Presentation Product Specification v1](../../../../docs/architecture/dialogue/07-presentation-product-spec.md)  
**Architecture:** [ADR-014](../../../../docs/architecture/dialogue/decisions/014-product-structure-and-presentation.md) · [ADR-015–019](../../../../docs/architecture/dialogue/decisions/015-presentation-product-concepts.md) · [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md)  
**v1 reference scope:** [reference-content-v1.md](reference-content-v1.md)

This folder is the **Presentation subsystem** of the Dialogue Framework product. It is **not** part of Runtime.

## Purpose

Reusable dialogue presentation technology:

- Dialogue HUD **layout scenes** (primary consumer surface)
- **Theme**, **Policy**, and **Input** resources (editor-first customization)
- `IDialoguePresenter` reference implementation (`DialoguePresenter`) with **slot/bridge nodes**
- Typewriter/reveal, tag timing (`#voice`, `#time`), choice/speaker UX
- Default dialogue UX input (skip, advance, choice navigation)
- Optional Ui React per-control composition via slot variants (not a separate product path)

## Product concepts

| Concept | Customize by |
|---------|--------------|
| **Layout** | Duplicate layout scene; edit in Godot scene editor |
| **Theme** | Duplicate Theme `.tres`; assign on presenter |
| **Policy** | Duplicate Policy `.tres`; assign on presenter |
| **Input** | Duplicate Input `.tres`; assign on layout **InputListener** |

**Resource assignment:** Theme and Policy on **Presenter**; Input on **InputListener** (ADR-016). All reference layouts wire `hud_root_slot_path` for consistent show/hide behavior.

See [game_presenter.md](../docs/game_presenter.md) for integration and [reference-content-v1.md](reference-content-v1.md) for v1 assets.

## Layout slot convention (ADR-015 D21.4)

Reference layouts expose identifiable regions consumers must preserve when duplicating or rearranging panels. Node names in the shipped reference scenes:

| Slot region | Reference node name | Purpose |
|-------------|---------------------|---------|
| **Speaker** | `SpeakerLabel` | Speaker name display |
| **Line** | `LineText` | BBCode line text |
| **Choices** | `ChoicesStack` | Choice button container |
| **Line panel** | `LinePanel` | Line visibility area |
| **Choices panel** | `ChoicesPanel` | Choices visibility area |
| **Hud root** | `HudRoot` | Full HUD visibility (wired on all reference layouts) |

Each region is wired through a **child slot node** under `presentation/slots/` (native or Ui React variant). `DialogueHudRootSlot` and `DialogueHudRootSlotUiReact` share the `set_root_visible` / `clear` contract. `DialoguePresenter` exports `NodePath` values to those slot nodes—not directly to leaf controls. Portrait regions are reserved for a future ADR and are not required in v1.

### Choices region layout contract

Reference layouts use shrink-to-fit choices regions (ADR-018 D24.1):

- `ChoicesPanel`: bottom-anchored, fixed width, `offset_top == offset_bottom` (height from children)
- `ChoicesStack`: `size_flags_vertical = 0` (shrink), `alignment = 0` (top)
- `ChoicesPanelSlot`: `apply_line_panel_chrome = false`
- `LinePanelSlot`: default `apply_line_panel_chrome = true`

Choice **count** sizing is a Layout concern (`ChoicesStack` shrink + bottom anchor). Choice **row** sizing uses Theme tokens (`choice_min_size`, `choice_separation`). Policy `line_overflow_mode` applies to line text only—not the choices panel.

Policy line-text configuration (via `apply_line_overflow`) also sets `visible_characters_behavior = VC_CHARS_AFTER_SHAPING` alongside `AUTOWRAP_WORD_SMART` per overflow mode, so typewriter reveal shapes the full line before clipping and words do not jump to the next line mid-reveal.

## Boundaries

| Presentation may | Presentation must not |
|------------------|----------------------|
| Import `runtime/` and `data/` | Be imported by `runtime/` |
| Use native Godot `Control` nodes | Traverse dialogue graphs or mutate game state |
| Optionally use `addons/ui_react/` per control in layout scenes | Require Ui React |
| Ui React slot scripts import Ui React | Import Ui React in `dialogue_presenter.gd` |

## Reference assets (current baseline)

See [reference-content-v1.md](reference-content-v1.md) for full v1 scope and target resource model.

### Presenter (integration infrastructure)

| Asset | Path |
|-------|------|
| Canonical presenter | `res://addons/dialogue_framework/presentation/dialogue_presenter.gd` |
| Shared line reveal | `res://addons/dialogue_framework/presentation/dialogue_line_reveal.gd` |
| Native slot scripts | `res://addons/dialogue_framework/presentation/slots/dialogue_*_slot.gd` |
| Ui React slot scripts | `res://addons/dialogue_framework/presentation/slots/dialogue_*_slot_ui_react.gd` |

### Native baseline (required without Ui React)

| Asset | Path |
|-------|------|
| Native layout | `res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn` |
| Choices-right variant | `res://addons/dialogue_framework/presentation/native_dialogue_hud_choices_right.tscn` |

### Ui React composition (optional per control)

| Asset | Path |
|-------|------|
| Full Ui React layout | `res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn` |
| Mixed example (native speaker + Ui React line) | `res://addons/dialogue_framework/presentation/dialogue_hud_mixed_example.tscn` |
| Ui React UI states | `res://addons/dialogue_framework/presentation/ui_states/*.tres` |

Layouts may mix native and Ui React controls by swapping slot script variants on a per-region basis. Theme, Policy, and Input resources are shared across control mixes.

## Demo consumption

The dialogue showcase demo (`game/dialogue_demo/`) instances the Ui React reference layout:

- `game/dialogue_demo/scenes/dialogue_demo.tscn` → `ui_react_dialogue_hud.tscn`

Games adopting the **native baseline** should instance `native_dialogue_hud.tscn` without requiring Ui React.

## Testing

Native layout integration coverage: `tests/unit/test_native_presentation_hud_integration.gd`  
Mixed layout coverage: `tests/unit/test_presentation_mixed_layout_integration.gd`  
Slot unit tests: `tests/unit/test_presentation_slot_contract.gd`  
Presenter boundary: `tests/unit/test_presentation_presenter_boundary.gd`

```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://addons/dialogue_framework/tests/unit -ginclude_subdirs \
  -gselect=test_presentation -gexit
```

Full suite: [../README.md](../README.md#testing)

## Related

- [game_presenter.md](../docs/game_presenter.md) — Contract and product guide
- [extension_points.md](../docs/extension_points.md) — Runtime extension points
- [07-presentation-product-spec.md](../../../../docs/architecture/dialogue/07-presentation-product-spec.md) — Frozen product specification v1
