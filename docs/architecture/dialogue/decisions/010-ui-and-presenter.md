# ADR 010: UI and Presenter

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D11.1–D11.7

## Context

3D action RPG uses subtitle-style dialogue, not VN portrait layouts. DM separates balloon from engine; framework must not own production UI.

## Decision

1. **Game-owned presenter** — framework does not ship production UI (D11.1).
2. **IDialoguePresenter:** `present(step)`, `dismiss()` only — no `on_choice` callback; game calls `controller.choose(index)` (D11.2).
3. **Game pauses player** on conversation start (D11.3).
4. **No portraits in v1** — subtitle + speaker name only (D11.4).
5. **Typewriter in presenter** — DM `DialogueLabel` pattern in game code (D11.5).
6. **BBCode RichTextLabel** (D11.6).
7. **`#voice=path` tag** — presenter plays audio; calls `notify_presentation_finished()` on finish (D11.7). Presenter blips are optional.

### v1 presentation constraints

- **Do not use `#portrait` tag.**
- **Do not add portrait field to `ConversationStep`.**
- Speaker display via `tr(speaker_id, "speakers")` in presenter subtitle.

## Consequences

- Every game project builds its own presenter scene.
- Presenter owns typewriter, voice, and `#time` timers.
- Portrait support requires future ADR and presenter contract changes.

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [05-open-questions.md](../05-open-questions.md)
