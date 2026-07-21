# ADR 010: UI and Presenter

**Status:** Accepted (amended by ADR-014)  
**Date:** 2026-07-05  
**Decisions:** D11.1–D11.7

## Context

3D action RPG uses subtitle-style dialogue, not VN portrait layouts. Dialogue Manager separates balloon from **engine** (runtime traversal); the Dialogue Framework adopts the same **runtime/presentation layer split**. ADR-014 clarifies that reusable presentation technology lives in the **Presentation subsystem**, not in Runtime.

## Decision

1. **Runtime does not ship production UI (D11.1)** — The Runtime subsystem (`runtime/`) does not instantiate dialogue HUD scenes or implement presentation. The **Presentation subsystem** (`presentation/`) provides reusable dialogue presentation implementations. Games wire a presenter into `ConversationController.start()`; they are not required to author all presentation technology from scratch.
2. **`IDialoguePresenter` contract (D11.2)** — Defined in Runtime: `present(step)`, `dismiss()`, and default no-op `refresh_line_text(step)` (ADR-023). No `on_choice` callback; game or presentation layer wires choice UI to `ConversationController.choose(index)`.
3. **Game pauses player** on conversation start (D11.3) — game orchestration responsibility.
4. **No portraits in v1** — subtitle + speaker name only (D11.4).
5. **Typewriter in Presentation (D11.5)** — DM `DialogueLabel` pattern; owned by Presentation implementations, not Runtime.
6. **BBCode RichTextLabel policy (D11.6)** — Presentation displays `step.text` with BBCode enabled.
7. **`#voice=path` tag (D11.7)** — Runtime stores tags on `ConversationStep`; Presentation plays audio and calls `notify_presentation_finished()` on finish. Optional text blips during typewriter are game-specific.

### v1 presentation constraints

- **Do not use `#portrait` tag.**
- **Do not add portrait field to `ConversationStep`.**
- Speaker display via `tr(speaker_id, "speakers")` in Presentation.

## Consequences

- Presentation subsystem owns typewriter, voice, and `#time` timer **policy** and reference implementations.
- Games may use Presentation reference scenes or custom `IDialoguePresenter` classes.
- Portrait support requires future ADR and presenter contract changes.
- See ADR-014 for product structure and dependency rules.

## Localization amendment (ADR-022)

- **Presentation-ready text (ADR-022 D28.4, D28.6):** Line body text and choice option labels delivered on `ConversationStep` are already localized for the active locale by Runtime. Presentation displays these strings (including BBCode via `RichTextLabel` per D11.6) and must not perform translation-catalog lookup for line body or choice labels, and must not traverse `CompiledDialogue` to localize authored text.
- **Speaker resolution unchanged (ADR-020 D26.16, ADR-022 D28.6):** The v1 constraint "Speaker display via `tr(speaker_id, "speakers")` in Presentation" is retained. `speaker_id` is delivered language-neutral; resolving the speaker display name is the single Presentation translation-resolution case. This is a clarification of the D26.5 display-vs-translation-resolution split, not a reversal of D11.4.
- **`IDialoguePresenter` and locale refresh (ADR-022 D28.18; ADR-023):** Localized strings are supplied on `present(step)` delivery. During `AwaitingChoice` locale refresh, Runtime may also call `refresh_line_text(step)` so a co-visible prompting LINE updates in place without rebuilding choices (ADR-023). Custom presenters may keep the default no-op.

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [05-open-questions.md](../05-open-questions.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
- [decisions/020-localization-architecture.md](020-localization-architecture.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
- [decisions/023-awaiting-choice-co-visible-locale-refresh.md](023-awaiting-choice-co-visible-locale-refresh.md)
