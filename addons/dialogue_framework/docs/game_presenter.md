# Presenter Contract and Presentation Responsibilities

The Dialogue Framework product has two subsystems: **Runtime** (headless execution) and **Presentation** (dialogue UI technology). See [ADR-014](../../../../docs/architecture/dialogue/decisions/014-product-structure-and-presentation.md) and [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md).

**Runtime** ships the **`IDialoguePresenter` interface** only (`runtime/i_dialogue_presenter.gd`). **Presentation** (`presentation/`) provides reusable implementations, scenes, and settings. **Games** wire a presenter into `ConversationController.start()` and handle orchestration (`GameContext`, commands, input routing).

Architecture references: [ADR-010 UI and Presenter](../../../../docs/architecture/dialogue/decisions/010-ui-and-presenter.md), [04-runtime-and-integration.md](../../../../docs/architecture/dialogue/04-runtime-and-integration.md).

---

## Runtime contract (`IDialoguePresenter`)

The interface exposes exactly two methods:

| Method | When called | Responsibility |
|--------|-------------|----------------|
| `present(step: ConversationStep)` | After `ConversationController` emits `step_ready(step)` | Render the current `LINE` or `CHOICES` step |
| `dismiss()` | On `cancel()`, before `COMMAND` execution when a line is visible, and when the conversation ends | Hide or clear dialogue UI |

**Not part of the contract:**

- No `on_choice` callback — Presentation or game wires choice UI to `ConversationController.choose(index)` (D11.2).
- The presenter must **not** call `DialogueRunner`, read `CompiledDialogue`, or advance the conversation directly.
- The presenter **must** call `ConversationController.notify_presentation_finished()` when a `LINE` step is ready for the next input (see below).

**Test double:** `tests/helpers/mock_dialogue_presenter.gd` — minimal Runtime integration stub (not production UI).

---

## Presentation subsystem responsibilities

Owned by `presentation/` (ADR-014). Not owned by Runtime or Ui React.

| Area | Presentation owns |
|------|-------------------|
| **Implementations** | Classes extending `IDialoguePresenter` |
| **Layouts / scenes** | `.tscn` dialogue HUD variants |
| **Settings / themes** | `.tres` presentation resources (typewriter delay, styles, etc.) |
| **Typewriter / reveal** | Policy and implementation (D11.5) |
| **BBCode display** | RichTextLabel policy (D11.6) |
| **Tags** | Interpret `#voice`, `#time`, `#time=auto` (D11.7, D13.5) |
| **Choices / speaker** | UX for `CHOICES` and speaker labels |
| **Ui React path** | Optional adapter using `addons/ui_react/` |
| **Native Godot path** | Required baseline without Ui React |

Presentation **must not** require Ui React. Dialogue Framework and Runtime **must not** depend on Ui React.

---

## v1 presentation constraints (D11.4)

Subtitle-style dialogue for 3D action RPG:

- **Subtitle text + speaker name only** — no portrait images in v1.
- **Do not use `#portrait`** — the tag is rejected at compile time.
- **`ConversationStep` has no portrait field** — do not add one in presenters.

Speaker display name:

```gdscript
tr(step.speaker_id, "speakers")
```

No speaker registry ships with the framework; use Godot translation CSV/domain `speakers` (D13.3).

---

## Game integration checklist (D11.3)

1. Implement `GameContext` for game state.
2. **Pause or restrict player control** when starting a conversation (`ConversationController.start()`).
3. Obtain or implement an `IDialoguePresenter` (Presentation reference or custom).
4. Pass the presenter instance to `start(compiled, entry, context, presenter)`.
5. Route input (skip typewriter, advance, choice confirm) as needed.
6. Wire choice selection to `ConversationController.choose(option_index)` if not handled inside the presenter.
7. Restore player control on `conversation_ended` or `conversation_cancelled`.

Games are **not** expected to author all presentation technology from scratch when using Presentation reference implementations.

---

## LINE step presentation (D11.5, D11.6)

For `ConversationStepKind.LINE` — **Presentation policy**:

1. Resolve speaker label with `tr(step.speaker_id, "speakers")`.
2. Display `step.text` in a **`RichTextLabel`** with BBCode enabled (D11.6).
3. Run a **typewriter / reveal effect** (Dialogue Manager `DialogueLabel` pattern).
4. When the line is fully revealed **and** any tag-driven timers/audio complete, call:

   ```gdscript
   ConversationController.notify_presentation_finished()
   ```

5. The game or presenter then calls `ConversationController.advance()` when the player is ready for the next step.

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

| Tag | Presentation responsibility |
|-----|----------------------------|
| `#voice=<path>` | Play voice audio at `res://` path. Call `notify_presentation_finished()` when playback completes (D11.7). Optional text blips during typewriter are game-specific. |
| `#time=auto` | After typewriter completes, start a timer: `visible_text.length() * 0.02` seconds (BBCode stripped), clamped to **0.5s–8.0s**. Then call `notify_presentation_finished()` (D13.5). |
| `#time=<N>` | Start an `N` second timer after typewriter completes, then call `notify_presentation_finished()`. |

**Runtime** stores tags on the step only. **Presentation** interprets them.

---

## What Runtime does not provide

- Dialogue HUD scene instantiation
- Production subtitle/layout scenes (Presentation subsystem)
- Built-in typewriter, voice, or `#time` timer logic (Presentation)
- Choice UI widgets (Presentation)

---

## Related architecture

- [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md) — Subsystems and dependencies
- [02-authoring-format.md](../../../../docs/architecture/dialogue/02-authoring-format.md) — Authoring syntax and tags
- [01-architecture-overview.md](../../../../docs/architecture/dialogue/01-architecture-overview.md) — Controller API and signals
- [presentation/README.md](../presentation/README.md) — Presentation folder boundaries
