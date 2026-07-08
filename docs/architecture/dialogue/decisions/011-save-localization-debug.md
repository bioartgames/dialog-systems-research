# ADR 011: Save, Localization, and Debug

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D12.1–D12.6, D13.1–D13.5, D14.1–D14.4

## Context

Neither reference plugin owns game save. Godot `TranslationServer` is native i18n. Runtime should stay headless—game provides debug UI.

## Decision

### Save/Load (D12.x)

1. **Game save owns state**; `DialogueSnapshot` helper only (D12.1).
2. **Snapshot fields:** `resource_uid`, `entry_label`, `line_id` (D12.2).
3. **Resume re-presents line** from start — no typewriter restore (D12.3). Presentation subsystem handles re-display.
4. **Snapshot valid between steps only** (D12.4).
5. **`resume()` uses `line_id` only** — `entry_label` for debug/metadata (D12.5).
6. **`to_dict()` / `from_dict()`** helpers on `DialogueSnapshot` (D12.6).

### Localization (D13.x)

1. **TranslationServer + `translation_key`** on lines (D13.1).
2. **`[id:key]` or `{source_path}::{line_number}`** (D13.2).
3. **`tr(speaker_id, "speakers")`** for speaker names (D13.3) — resolved in Presentation.
4. **`ConversationController` handles `NOTIFICATION_TRANSLATION_CHANGED`:** if phase is `PresentingLine` or `AwaitingInput`, re-build LINE step from current `line_id` and call `presenter.present(step)` (D13.4).
5. **`#time=auto`:** `length * 0.02s`, min 0.5s, max 8.0s after BBCode strip (D13.5) — Presentation policy.

### Debug (D14.x)

1. **Debug gated** by debug build/setting (D14.1).
2. **Step trace logging** in debug (D14.2).
3. **`source_line_number`** on `CompiledLine` (D14.3).
4. **`get_debug_state()`** keys: `phase`, `line_id`, `entry_label`, `resource_path`, `step_kind`. `resource_path` = `CompiledDialogue.source_path`; `resource_uid` in snapshot = `CompiledDialogue.resource_uid` (D14.4).

## Consequences

- Game embeds snapshot dict in its save format.
- No framework debug overlay (game provides debug UI).
- Presentation handles `#time=auto` timer policy and calls `notify_presentation_finished()`.

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [03-compilation-and-data.md](../03-compilation-and-data.md)
- [06-product-structure.md](../06-product-structure.md)
