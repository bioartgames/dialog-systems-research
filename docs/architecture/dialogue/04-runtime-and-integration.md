# Runtime and Integration

**Decisions:** D6.1–D6.10, D7.1–D7.8, D8.1–D8.7, D9.1–D9.6, D10.1–D10.6, D11.1–D11.7

---

## Execution model (D6.1)

`DialogueRunner` uses recursive skip-until-yield traversal (DM `get_line` pattern):

1. Load cursor line from graph.
2. Skip `CONDITION` (evaluate; follow true/false branch), `GOTO`, `TITLE` without yielding.
3. Yield `LINE`, `CHOICES`, `COMMAND`, `WAIT`, or `END` as `ConversationStep`.

False condition branches use sibling chain linking (D6.4).

---

## Step yield rules (D6.2, D6.5)

| Source | Yields | Controller behavior |
|--------|--------|---------------------|
| Dialogue line | `LINE` | Present via presenter; wait for `notify_presentation_finished()` |
| Choice group | `CHOICES` | Set `AwaitingChoice` → `step_ready` → `present(CHOICES)` (D6.9) |
| `@command` (except `@wait`) | `COMMAND` | See command sequence below (D6.8) |
| `@wait` | `WAIT` | Await duration, auto `advance()`; no presenter (D6.5) |
| `=> END` | `END` | Emit `conversation_ended(compiled)` |

---

## COMMAND execution sequence (D6.8)

On `advance()` when next step is `COMMAND`:

1. Set phase `ExecutingCommand`
2. Optionally `presenter.dismiss()` if line visible
3. Await `CommandRegistry` handler
4. Emit `command_executed(command_name, args)`
5. Auto `advance()` to next step

---

## CHOICES flow (D6.9)

On `advance()` when next is `CHOICES`:

1. Runner yields `CHOICES` step (only options passing conditions included)
2. Set phase `AwaitingChoice`
3. Emit `step_ready(step)`
4. `presenter.present(CHOICES)`
5. Game UI calls `choose(index)` → cursor set to `options[index].target_line_id`

If zero options pass: debug assert, emit `conversation_ended(compiled)`, phase `Ended` (D6.10).

---

## Cancel (D6.7)

`cancel()` immediately:

- Phase → `Ended`
- `presenter.dismiss()`
- Runner cursor cleared
- Emit `conversation_cancelled`

In-flight async command handlers are not awaited or aborted.

---

## Error handling (D15.2)

On invalid cursor / missing line (release builds):

- `push_error` with `line_id` + `resource_path`
- Phase → `Ended`
- `presenter.dismiss()`
- Emit `conversation_ended(compiled)`

---

## CommandRegistry (D7.1, D7.8)

Runtime dispatch for `@commands`. Game registers in `_ready()` before any `start()`.

```gdscript
CommandRegistry.register("camera", _handle_camera)
# handler(args: PackedStringArray) -> void  # may await
```

Duplicate registration → `push_error`.

### Built-ins (D7.2, D7.5)

| Command | Behavior |
|---------|----------|
| `@wait` | Yields WAIT step (D6.5) |
| `@set_flag` | Calls `GameContext.set_flag()` (D9.3) |
| `@emit` | Emits `command_executed("emit", args)` on controller (D7.5) |

---

## GameContext (D9.1, D9.2, D10.1)

Abstract class injected per `start()`. No dialogue-owned variable store.

### Minimum methods

| Method | Used by |
|--------|---------|
| `get_flag(name) -> Variant` | ConditionEvaluator, `{brace}` |
| `set_flag(name, value) -> void` | `@set_flag` |
| `has_item(item_id) -> bool` | ConditionEvaluator |
| `give_item(item_id, count=1) -> void` | Game commands |
| `remove_item(item_id, count=1) -> void` | Game commands |
| `get_quest_state(quest_id) -> String` | ConditionEvaluator |
| `start_quest(quest_id) -> void` | Game commands |
| `complete_quest(quest_id) -> void` | Game commands |
| `get_display_value(key) -> String` | `{brace}` interpolation |
| `get_binding(key) -> Variant` | Per-start bindings (`npc_id`, etc.) |

`ConditionEvaluator` may only call the above methods plus literal operators (D8.2).

---

## Game integration patterns (D10.2–D10.6)

| Pattern | Approach |
|---------|----------|
| `@open_shop` | Ends/pauses dialogue; switches to shop game mode (D10.2) |
| `@cutscene` | Async; UI hidden; requires game `CutsceneDirector` (D10.3) |
| Quest progression | Context methods + registering `@commands` (D10.4) |
| Inventory checks | `has_item` in evaluator; give/remove via commands (D10.5) |
| `@camera`, `@anim` | Game-registered 3D commands (D10.6) |

All game `@commands` must appear in `CommandManifest` for import to succeed.

---

## IDialoguePresenter (D11.1, D11.2)

Game implements presentation. Framework does not ship production UI.

```gdscript
func present(step: ConversationStep) -> void
func dismiss() -> void
```

- **No `on_choice` callback** — game wires choice UI to `ConversationController.choose(index)`.
- Presenter calls `notify_presentation_finished()` when typewriter, voice, or `#time` timer completes (D11.5, D11.7, D13.5).
- Presenter does not call `DialogueRunner` or read `CompiledDialogue`.

### v1 UI constraints (D11.4, D11.6)

- **Subtitle + speaker name only** — no portrait images.
- BBCode via `RichTextLabel` in game presenter.
- Game pauses player on conversation start (D11.3).

---

## ConditionEvaluator (D8.1)

Dedicated testable class. Interprets pre-tokenized condition arrays from compiled lines against injected `GameContext`. See [02-authoring-format.md](02-authoring-format.md) for token grammar.

---

## Related documents

- [01-architecture-overview.md](01-architecture-overview.md) — Phases and API summary
- [03-compilation-and-data.md](03-compilation-and-data.md) — Data schemas
- [decisions/006-runtime-execution.md](decisions/006-runtime-execution.md) — ADR
- [decisions/009-game-integration.md](decisions/009-game-integration.md) — ADR
- [decisions/010-ui-and-presenter.md](decisions/010-ui-and-presenter.md) — ADR
