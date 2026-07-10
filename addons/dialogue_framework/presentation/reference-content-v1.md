# Presentation Reference Content — v1 Scope

**Authority:** [Presentation Product Specification v1](../../../../docs/architecture/dialogue/07-presentation-product-spec.md) · [ADR-019 Growth Constraints](../../../../docs/architecture/dialogue/decisions/019-presentation-growth-constraints.md)

This document defines the **v1 reference product content** Presentation should ship or target. It is a product scope statement, not an implementation checklist.

---

## Purpose

Reference content demonstrates the editor-first adoption model:

> Duplicate a layout scene → assign Theme and Policy → play.

Reference assets prove the native-only baseline (ADR-014 D20.5, ADR-015 D21.5) and document the slot convention (ADR-015 D21.4).

---

## v1 scope summary

| Category | v1 requirement |
|----------|----------------|
| **Layout style** | Subtitle-style only (ADR-010 D11.4) |
| **Portraits** | None |
| **Native baseline** | At least one layout functional without Ui React |
| **Layout variants** | Minimum one; target one or two (e.g. choices-below, choices-right) |
| **Theme** | Default reference Theme resource |
| **Policy** | Default reference Policy (typewriter, tags, overflow, reduced motion) |
| **Input** | Default reference Input resource |
| **Accessibility** | Policy reduced-motion support; Theme a11y variants (ADR-017) |

---

## Layout slot convention

Every reference layout must provide identifiable regions for:

| Region | Purpose |
|--------|---------|
| **Speaker** | Speaker name display |
| **Line** | BBCode line text |
| **Choices** | Choice list container |
| **Line panel** | Line visibility area |
| **Choices panel** | Choices visibility area |

Consumers may rearrange panels in the scene editor. Regions must remain connectable to Presentation.

Portrait region: **not in v1** (reserved for future ADR).

---

## Current reference assets (baseline)

These assets exist today and serve as the starting baseline. The product model in ADR-015–019 describes the **target** editor-first resource model; not all resource types are implemented yet.

### Layout scenes

| Asset | Role | Ui React |
|-------|------|----------|
| `native_dialogue_hud.tscn` | Native-only subtitle layout (required baseline) | No |
| `native_dialogue_hud_choices_right.tscn` | Native layout with choices panel on the right | No |
| `ui_react_dialogue_hud.tscn` | Subtitle layout with Ui React controls on speaker/line/panels | Per control |
| `dialogue_hud_mixed_example.tscn` | Documented mixed composition (native speaker, Ui React line) | Partial |

All reference layouts follow the shrink-to-fit **choices region layout contract** (see [README.md](README.md)).

### Presenter and slots (integration infrastructure)

| Asset | Role |
|-------|------|
| `dialogue_presenter.gd` | Canonical `IDialoguePresenter`; orchestration only (no Ui React imports) |
| `dialogue_line_reveal.gd` | Shared BBCode-safe typewriter/reveal (used by native and Ui React line slots; not a customization surface) |
| `slots/dialogue_*_slot.gd` | Native output-binding slot scripts (speaker, line, panel, choices, hud root) |
| `slots/dialogue_*_slot_ui_react.gd` | Ui React slot variants (`text_state`, `visible_state`, choice bus) for mixed/full Ui React layouts |
| `slots/dialogue_choices_slot_ui_react.gd` | Choice index bus + template instantiation |
| `templates/choice_button_template.tscn` | UiReactButton prototype for Ui React layouts |

Presenters and slot scripts are pre-wired inside layout scenes. Consumers customize via Layout, Theme, Policy, and Input—not presenter scripts. Assign Theme and Policy on **Presenter**; assign Input on **InputListener**.

### Ui React states (optional)

| Asset | Role |
|-------|------|
| `ui_states/*.tres` | Ui React state resources used by `ui_react_dialogue_hud.tscn` |
| `ui_states/choice_selected_state.tres` | Shared int bus for choice selection index |

Mixed composition: layouts may use native controls on some slots and Ui React on others (ADR-015 D21.6).

---

## Target reference resources (product model)

The following resource types are defined by the product specification and ADRs. Implementation may introduce them incrementally.

### Theme (appearance)

**Owns:** speaker/line typography and color, line panel/banner styling, choices panel chrome (optional; default transparent), choice visual states, spacing tokens, accessibility visual variants (high contrast, large text).

**Choices panel tokens:** `choices_panel_bg_color`, `choices_panel_corner_radius`, `choices_panel_content_margin` (default transparent/zero).

**v1 default:** One reference Theme resource duplicatable per game.

### Policy (behavior)

**Owns:** typewriter/reveal, `#voice` / `#time` / `#time=auto` interpretation, choice interaction rules, panel chrome motion durations (`choices_intro_duration_sec`, `choices_dismiss_duration_sec`, `line_dismiss_duration_sec`), text overflow mode (grow / clamp / scroll), reduced motion behavior, optional alternate Theme reference under a11y conditions.

**v1 default:** One reference Policy resource duplicatable per game.

| Asset | Purpose |
|-------|---------|
| `resources/default_dialogue_policy_choices_juice.tres` | Showcase Policy: `choices_intro_duration_sec`, `choices_dismiss_duration_sec`, `line_dismiss_duration_sec` = 0.15 each (Ui React HUD) |

Layout `open_animation` / `dismiss_animation` on `DialoguePanelSlotUiReact` are layout-owned motion **recipes**; durations are Policy-owned at runtime. See [panel-motion-matrix.md](panel-motion-matrix.md).

### Input (dialogue UX mapping)

**Owns:** mapping from player actions to skip typewriter, advance line, navigate choices, confirm choice.

**v1 default:** One reference Input resource; consumed by default presentation input in reference layouts (ADR-016).

---

## Adoption tiers

### Minimum

1. Instance `native_dialogue_hud.tscn` (or successor native layout).
2. Wire presenter to `ConversationController.start()`.
3. Pause player on conversation start.

### Recommended

1. Duplicate closest layout variant.
2. Duplicate Theme and Policy; assign on presenter in Inspector.
3. Tweak visually in scene editor.

### Advanced

- Rearrange dialogue regions in layout scene.
- Mix native and Ui React controls per slot.
- Custom Input resource for rebinding.
- Theme variants for accessibility.
- Override presentation input from game when UI layers compete.

### Extension

- Custom `IDialoguePresenter` for non-screen-space dialogue.

---

## Out of v1 reference scope

| Item | Status |
|------|--------|
| Portrait layouts / `#portrait` | Future ADR (ADR-019) |
| VN, balloon, RPG box layout variants | Post-v1 product content |
| Screen reader / narration pipeline | Future ADR (ADR-017) |
| Presenter subclassing for customization | Not supported (ADR-018) |

---

## Verification expectations

- Native baseline layout runs without Ui React addon enabled.
- Presentation integration tests use layout scenes + `ConversationController`.
- Runtime headless tests do not require Presentation scenes.

---

## Related documents

- [07-presentation-product-spec.md](../../../../docs/architecture/dialogue/07-presentation-product-spec.md)
- [game_presenter.md](../docs/game_presenter.md)
- [README.md](README.md)
