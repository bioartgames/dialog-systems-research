# Panel motion matrix

**Authority:** ADR-015 (slot mediation), product spec §15/§17 (layout motion, Policy timing)

## Meta-path

```
DialoguePresenter  →  region slot (native / UiReact)  →  Control.visible + UiBoolState
                    ↓
              Policy duration (when blocking) + layout UiAnimTarget recipe (Ui React)
                    ↓
              Layout feedback (state_watch audio, etc.) — parallel only
```

Presenter never imports Ui React. Slots bridge Policy + optional `UiAnimTarget` exports configured in layout scenes.

## Lanes

| Lane | When | Presenter | Slot | Policy |
|------|------|-----------|------|--------|
| **A — Blocking** | Outro gates conversation flow | `await dismiss_panel()` | `dismiss_animation` + timer | Outro duration field |
| **B — Parallel** | Juice does not block flow | No await on show | `open_animation` fire-and-forget | Intro duration field |
| **Content** | Line text reveal | `await reveal_typewriter` | `DialogueLineSlot` | `typewriter_char_delay` |

Do not merge content lane (typewriter) with panel chrome fade.

## Transition matrix (implemented)

| Transition | Lane | Profile | Policy field | Presenter |
|------------|------|---------|--------------|-----------|
| Choices open (visual) | B | `CHOICES_INTRO_OUTRO` | `choices_intro_duration_sec` | `_show_choices_panel` → `set_panel_visible(true)` |
| Choices open (audio) | B | — | — | `state_watch` on `choices_panel_visible_state` (layout) |
| Choices close | A | `CHOICES_INTRO_OUTRO` | `choices_dismiss_duration_sec` | `await dismiss_panel` in `_run_line_entry` / `_run_full_dismiss` |
| Line close on `dismiss()` | A | `LINE_OUTRO` | `line_dismiss_duration_sec` | `await dismiss_panel` in `_run_full_dismiss` |
| Line open | — | `INSTANT` | — | instant |
| HUD show/hide | — | deferred | — | instant |

## `PanelMotionProfile` (on `DialoguePanelSlot`)

| Value | Intro source | Outro source |
|-------|--------------|--------------|
| `INSTANT` | none (0) | none (0) |
| `CHOICES_INTRO_OUTRO` | `choices_intro_duration_sec` | `choices_dismiss_duration_sec` |
| `LINE_OUTRO` | none (0) | `line_dismiss_duration_sec` |

Scene assigns profile per slot instance (`ChoicesPanelSlot` vs `LinePanelSlot`).

## Native vs Ui React parity

- **Policy semantics identical** (duration, `reduced_motion` → 0 via applier).
- **Native:** timer hold on blocking outro; parallel intro is visibility-only (no tween).
- **Ui React:** layout `open_animation` / `dismiss_animation` recipe; slot sets `duration` from Policy at apply time. Editor `.tscn` duration is preview only.

## Reduced motion

`DialoguePresentationResourceApplier._motion_duration()` returns `0.0` when `policy.reduced_motion` is true for all chrome durations.

## Phases

| Phase | Scope |
|-------|--------|
| 1 | Choices open parallel (`open_animation`, `choices_intro_duration_sec`) |
| 2 | Line outro on `presenter.dismiss()` (`LINE_OUTRO`, `line_dismiss_duration_sec`) |
| 3 | HUD — **documented only** (this section) |

## Future — HUD root (Phase 3 defer)

Proposed when product requires HUD chrome motion:

- `DialogueHudRootSlotUiReact.present_root()` / `dismiss_root()` mirroring panel API
- Policy: `hud_intro_duration_sec`, `hud_dismiss_duration_sec`
- Presenter: await HUD outro in `_run_full_dismiss` before final hide; parallel intro on `_show_line_panel`
- **Not implemented** in current initiative (YAGNI)

## Non-goals

- Ui React `state_watch` on `animation_targets` (plugin change)
- Presenter await on choices open
- Merging panel fade with typewriter
- `dismiss()` text preservation during line outro (line text cleared before outro today)
- Consumer presenter subclassing

## Known limitation

`presenter.dismiss()` calls `_cancel_active_line_presentation()` before `_run_full_dismiss()`, so line **text** is cleared before line panel outro; only panel chrome animates.
