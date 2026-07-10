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

### Panel chrome motion

See [panel-motion-matrix.md](panel-motion-matrix.md) for the full transition matrix, lane rules, and phased scope.

- **Lane A (blocking):** `dismiss_panel()` + Policy outro duration + presenter `await` (choices close, line close on `dismiss()`).
- **Lane B (parallel):** `set_panel_visible(true)` triggers `open_animation` fire-and-forget; presenter does **not** await intro.
- **Content lane:** typewriter via `DialogueLineSlot` — separate from panel fade.

`DialoguePanelSlot.motion_profile` (`INSTANT`, `CHOICES_INTRO_OUTRO`, `LINE_OUTRO`) selects which Policy duration fields apply per layout slot instance. Layout owns `open_animation` / `dismiss_animation` recipe (`UiAnimTarget`); Policy owns duration; slot overrides anim `.duration` at apply time. Editor `.tscn` anim duration is preview only.

Open **audio** uses `state_watch` on `choices_panel_visible_state` (layout). Open **visual** uses slot `open_animation` — not both for the same visual effect.

### Choice Ui React bus

Ui React layouts can drive choice animation, audio, and haptics without coupling `DialoguePresenter` to Ui React:

- `DialogueChoicesSlotUiReact` publishes `choice_selected_state` (`UiIntState`) when the presenter navigates, confirms, or clears selection (`-1` when no choice is active).
- `choice_button_template.tscn` is a `UiReactButton` prototype with demo `FOCUS_ENTERED` navigate pulse/audio and `PRESSED` confirm POP/audio/haptic; `DialoguePresenter` still applies Theme choice styles at runtime and calls `grab_focus()` on the active row so only that button animates.
- `Policy.choices_intro_duration_sec` / `choices_dismiss_duration_sec` gate choices panel intro (parallel) and outro (blocking).
- `Policy.line_dismiss_duration_sec` gates line panel outro on `presenter.dismiss()` (blocking).
- Choice→line handoff: presenter interrupts in-flight typewriter/voice but **keeps displayed speaker/line text** until dismiss completes.
- Demo wiring in `ui_react_dialogue_hud.tscn`: choices-panel-open audio via `state_watch`; choices open fade + dismiss fade via `ChoicesPanelSlot` `open_animation` / `dismiss_animation` + juice Policy.
- Native layouts keep `DialogueChoicesSlot` (runtime `Button.new()`); use the Ui React slot variant only when duplicating Ui React or mixed layouts.

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
Panel motion integration: `tests/unit/test_presentation_panel_motion_integration.gd`  
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
