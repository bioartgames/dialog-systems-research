# ADR 011: Save, Localization, and Debug

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D12.1–D12.6, D13.1–D13.5, D14.1–D14.4  
**Localization superseded by:** ADR-020 (complete localization model), ADR-021 (compile-time identity contract), ADR-022 (runtime delivery and locale switching). D13.1–D13.4 are historical context; D13.3 speaker behavior is retained (ADR-020 D26.16). See the Localization amendment section below.

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

### Localization (D13.x) — superseded as the complete model by ADR-020/021/022 (see Localization amendment below)

1. **TranslationServer + `translation_key`** on lines (D13.1).
2. **`[id:key]` or `{source_path}::{line_number}`** (D13.2).
3. **`tr(speaker_id, "speakers")`** for speaker names (D13.3) — resolved in Presentation. **Retained** (ADR-020 D26.16).
4. **`ConversationController` handles `NOTIFICATION_TRANSLATION_CHANGED`:** if phase is `PresentingLine` or `AwaitingInput`, re-build LINE step from current `line_id` and call `presenter.present(step)` (D13.4). **Extended by ADR-022 D28.10:** `AwaitingChoice` also performs a locale refresh, and every other phase has a defined guarantee.
5. **`#time=auto`:** Policy-timed hold after typewriter (D13.5). Presentation calls `notify_presentation_finished()` then auto-advances via `ConversationController.advance()`. **`#time=N`:** Presentation calls `notify_presentation_finished()` only; player must press Accept to advance.

### Debug (D14.x)

1. **Debug gated** by debug build/setting (D14.1).
2. **Step trace logging** in debug (D14.2).
3. **`source_line_number`** on `CompiledLine` (D14.3).
4. **`get_debug_state()`** keys: `phase`, `line_id`, `entry_label`, `resource_path`, `step_kind`. `resource_path` = `CompiledDialogue.source_path`; `resource_uid` in snapshot = `CompiledDialogue.resource_uid` (D14.4).

## Consequences

- Game embeds snapshot dict in its save format.
- No framework debug overlay (game provides debug UI).
- Presentation handles `#time=auto` / `#time=N` timer policy, calls `notify_presentation_finished()`, and auto-advances after `#time=auto` only.

## Localization amendment (ADR-020, ADR-021, ADR-022)

- **Complete model:** The complete localization architecture is ADR-020 (subsystem model), ADR-021 (compile-time identity contract), and ADR-022 (runtime delivery and locale switching). D13.1–D13.4 above are historical context superseded by that model; D13.3 speaker behavior is retained (ADR-020 D26.16).
- **Locale switching by phase (ADR-022 D28.10):** D13.4 LINE refresh (`PresentingLine` / `AwaitingInput`) is extended so that every `ConversationPhase` has a defined guarantee, including `AwaitingChoice` locale refresh; traversal semantics never change.
- **Missing-translation fallback (ADR-022 D28.8):** When translation resolution fails for a required translation identity, Runtime falls back to the compiled authoring-language source text preserved on the node (ADR-021 D27.9), applied identically to LINE body and choice labels, without `.dlg` parsing.
- **Save/resume (ADR-022 D28.13):** Snapshots persist coordinates only (`resource_uid`, `entry_label`, `line_id`); active locale and localized strings are not save data. `resume()` rebuilds localized delivery from compiled data using the **active locale at resume time** and does not require the save-time locale to match.

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [03-compilation-and-data.md](../03-compilation-and-data.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/020-localization-architecture.md](020-localization-architecture.md)
- [decisions/021-localized-authoring-compiled-identity.md](021-localized-authoring-compiled-identity.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
