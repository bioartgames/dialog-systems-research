# Game Presenter Responsibilities

This addon ships **`IDialoguePresenter` only** — no production dialogue UI (D11.1). Every game project implements its own presenter scene and wires it to `ConversationController.start()`.

Architecture references: [ADR-010 UI and Presenter](../../../../docs/architecture/dialogue/decisions/010-ui-and-presenter.md), [04-runtime-and-integration.md](../../../../docs/architecture/dialogue/04-runtime-and-integration.md).

---

## Presenter contract (`IDialoguePresenter`)

The interface exposes exactly two methods:

| Method | When called | Responsibility |
|--------|-------------|----------------|
| `present(step: ConversationStep)` | After `ConversationController` emits `step_ready(step)` | Render the current `LINE` or `CHOICES` step |
| `dismiss()` | On `cancel()`, before `COMMAND` execution when a line is visible, and when the conversation ends | Hide or clear dialogue UI |

**Not part of the contract:**

- No `on_choice` callback — the game wires choice UI buttons to `ConversationController.choose(index)` (D11.2).
- The presenter must **not** call `DialogueRunner`, read `CompiledDialogue`, or advance the conversation directly.
- The presenter **must** call `ConversationController.notify_presentation_finished()` when a `LINE` step is ready for the next input (see below).

---

## v1 presentation constraints (D11.4)

This framework targets **3D action RPG subtitle-style dialogue**:

- **Subtitle text + speaker name only** — no portrait images in v1.
- **Do not use `#portrait`** — the tag is rejected at compile time.
- **`ConversationStep` has no portrait field** — do not add one in game presenters.

Speaker display name:

```gdscript
tr(step.speaker_id, "speakers")
```

No speaker registry ships with the framework; use Godot translation CSV/domain `speakers` (D13.3).

---

## Game integration checklist (D11.3)

1. Implement `IDialoguePresenter` on a `Node` in your UI scene.
2. **Pause or restrict player control** when starting a conversation (`ConversationController.start()`).
3. Pass the presenter instance to `start(compiled, entry, context, presenter)`.
4. Listen to `step_ready` if you need to react before `present()` (optional; controller calls `present()` immediately after emitting).
5. Wire choice buttons to `ConversationController.choose(option_index)`.
6. Restore player control on `conversation_ended` or `conversation_cancelled`.

---

## LINE step presentation (D11.5, D11.6)

For `ConversationStepKind.LINE`:

1. Resolve speaker label with `tr(step.speaker_id, "speakers")`.
2. Display `step.text` in a **`RichTextLabel`** with BBCode enabled (D11.6).
3. Run a **typewriter / reveal effect** in game code (Dialogue Manager `DialogueLabel` pattern).
4. When the line is fully revealed **and** any tag-driven timers/audio complete, call:

   ```gdscript
   ConversationController.notify_presentation_finished()
   ```

5. The game (or presenter) then calls `ConversationController.advance()` when the player is ready for the next step.

`WAIT` and `COMMAND` steps are handled by the controller — the presenter is not called for those step kinds.

---

## CHOICES step presentation (D6.9)

For `ConversationStepKind.CHOICES`:

1. Present `step.options` (already filtered by conditions at step-build time).
2. Display each option's `text` field.
3. On player selection, call `ConversationController.choose(index)` with the option's `index` field — **not** an `on_choice` presenter callback.

---

## Tag handling (D4.8, D11.7, D13.5)

Tags are compiled onto `ConversationStep.tags` as `PackedStringArray` entries (`#voice=path`, `#time=auto`, `#time=1.5`, etc.).

| Tag | Presenter responsibility |
|-----|--------------------------|
| `#voice=<path>` | Play voice audio at `res://` path. Call `notify_presentation_finished()` when playback completes (D11.7). Optional text blips during typewriter are game-specific. |
| `#time=auto` | After typewriter completes, start a timer: `visible_text.length() * 0.02` seconds (BBCode stripped), clamped to **0.5s–8.0s**. Then call `notify_presentation_finished()` (D13.5). |
| `#time=<N>` | Start an `N` second timer after typewriter completes, then call `notify_presentation_finished()`. |

Tags are **metadata for the presenter** — the framework does not interpret them at runtime beyond storing them on the step.

---

## What the framework does not provide

- Production subtitle/HUD scenes
- Portrait layouts or `#portrait` support
- Built-in typewriter, voice, or `#time` timer logic
- Choice UI widgets

Implement these in your game's presenter layer. See `tests/helpers/mock_dialogue_presenter.gd` for a minimal test double.

---

## Related architecture

- [02-authoring-format.md](../../../../docs/architecture/dialogue/02-authoring-format.md) — Authoring syntax and tags
- [01-architecture-overview.md](../../../../docs/architecture/dialogue/01-architecture-overview.md) — Controller API and signals
