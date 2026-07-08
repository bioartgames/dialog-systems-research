# ADR 010: UI and Presenter

**Status:** Accepted (amended by ADR-014)  
**Date:** 2026-07-05  
**Decisions:** D11.1–D11.7

## Context

3D action RPG uses subtitle-style dialogue, not VN portrait layouts. Dialogue Manager separates balloon from **engine** (runtime traversal); the Dialogue Framework adopts the same **runtime/presentation layer split**. ADR-014 clarifies that reusable presentation technology lives in the **Presentation subsystem**, not in Runtime.

## Decision

1. **Runtime does not ship production UI (D11.1)** — The Runtime subsystem (`runtime/`) does not instantiate dialogue HUD scenes or implement presentation. The **Presentation subsystem** (`presentation/`) provides reusable dialogue presentation implementations. Games wire a presenter into `ConversationController.start()`; they are not required to author all presentation technology from scratch.
2. **`IDialoguePresenter` contract (D11.2)** — Defined in Runtime: `present(step)`, `dismiss()` only. No `on_choice` callback; game or presentation layer wires choice UI to `ConversationController.choose(index)`.
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

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [05-open-questions.md](../05-open-questions.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
