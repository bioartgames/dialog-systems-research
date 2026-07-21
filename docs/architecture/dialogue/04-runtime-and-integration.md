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
| `=> END` | `END` | Transition to Ended, dismiss presenter, emit `conversation_ended(compiled)`, cleanup to Idle |

---

## COMMAND execution sequence (D6.8)

On `advance()` when next step is `COMMAND`:

1. Set phase `ExecutingCommand`
2. Optionally `presenter.dismiss()` if a line was visible and the command requires UI teardown
3. Await `CommandRegistry` handler (built-ins run inline)
4. Emit `command_executed(command_name, args)` (except `@emit`, which uses built-in payload per D7.5)
5. Auto `advance()` to next step

**Dismiss is optional (D6.8), not mandatory for every command.**

| When advancing from `AwaitingInput` | Dismiss? |
|-------------------------------------|----------|
| Game-registered commands (`@open_shop`, `@cutscene`, `@camera`, etc.) | Yes — UI may switch to another game mode (ADR-009 D10.2–D10.3) |
| Built-in non-visual commands (`@set_flag`, `@emit`) | No — state/signal side effects only; dialogue continues inline |
| `@wait` | N/A — yields `WAIT` step; presenter never involved (D6.5) |

Consecutive built-in commands (`@set_flag` then `@emit`) auto-advance without dismiss between them; only the first command is entered from `AwaitingInput`.

---

## CHOICES flow (D6.9)

On `advance()` when next is `CHOICES`:

1. Runner yields `CHOICES` step (only options passing conditions included)
2. Set phase `AwaitingChoice`
3. Emit `step_ready(step)`
4. `presenter.present(CHOICES)`
5. Game UI calls `choose(index)` → cursor set to `options[index].target_line_id`

If zero options pass: debug assert, emit `conversation_ended(compiled)`, phase `Ended` (D6.10).

Each visible option label is delivered **already localized** for the active locale (ADR-022 D28.4, D28.5); labels are static text in v1 (D28.14). Option order, `target_line_id`, and `index` remain language-neutral.

---

## Cancel (D6.7)

`cancel()` immediately:

- Phase → `Ended`
- `presenter.dismiss()`
- Runner cursor cleared
- Emit `conversation_cancelled`

In-flight async command handlers are not awaited or aborted.

Natural `=> END` completion also dismisses the presenter, so players do not need Cancel to close the dialogue HUD after the final line.

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

Games may implement `GameContext` directly, or adopt the optional Integration kit’s Resource/dictionary-backed reference implementation (ADR-024). Either way, **authoritative** flags/items/quests/save data remain game-owned (D1.1); kit maps are configuration aids, not the save system.

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

Optional **Integration kit** (ADR-024) may provide a conversation starter Node and command bridge Resource that configure these patterns via Inspector exports without changing Runtime contracts. Adoption is optional; custom orchestration remains valid.

---

## IDialoguePresenter (D11.1, D11.2, ADR-014)

**Runtime** defines the contract in `runtime/i_dialogue_presenter.gd`. **Presentation** provides implementations. **Games** wire a presenter instance into `ConversationController.start()` — directly or via the optional Integration starter (ADR-024).

Runtime does not ship production dialogue UI. The Presentation subsystem provides reusable reference implementations (optional to adopt).

```gdscript
func present(step: ConversationStep) -> void
func dismiss() -> void
```

- **No `on_choice` callback** — Presentation or game wires choice UI to `ConversationController.choose(index)`.
- Presenter calls `notify_presentation_finished()` when typewriter, voice, or `#time` timer completes (D11.5, D11.7, D13.5).
- After `#time=auto`, Presentation may call public `ConversationController.advance()` immediately after `notify_presentation_finished()` to auto-advance; Runtime phase rules are unchanged.
- Presenter does not call `DialogueRunner` or read `CompiledDialogue`.
- Line body and choice-label text on the step are **already localized** by Runtime; the presenter does not perform translation-catalog lookup for authored text. It resolves the speaker display name via `tr(speaker_id, "speakers")` (ADR-020 D26.16, ADR-022 D28.6). No `IDialoguePresenter` change is required for v1 (ADR-022 D28.18).

### v1 UI constraints (D11.4, D11.6)

- **Subtitle + speaker name only** — no portrait images.
- BBCode via `RichTextLabel` in Presentation implementations.
- Game pauses player on conversation start (D11.3).

---

## ConditionEvaluator (D8.1)

Dedicated testable class. Interprets pre-tokenized condition arrays from compiled lines against injected `GameContext`. See [02-authoring-format.md](02-authoring-format.md) for token grammar.

---

## Localization and locale switching (ADR-020, ADR-022)

- **Localized delivery (ADR-022 D28.4, D28.5):** Runtime resolves LINE body text and each visible choice label by translation identity (ADR-021) and delivers presentation-ready localized strings on the step. Traversal fields stay language-neutral; the speaker name is resolved in Presentation (ADR-020 D26.16).
- **Missing translation (ADR-022 D28.8):** When resolution fails for a required identity, Runtime falls back to the compiled authoring-language source text (ADR-021 D27.9) for both LINE and choice labels, without parsing `.dlg`.
- **Incomplete resources (ADR-022 D28.9):** Pre-contract CHOICE resources lacking choice-label identity deliver compiled source text (degraded) until reimport; Runtime never infers identity from source at runtime.
- **Locale switching by phase (ADR-022 D28.10, D28.12; ADR-023):** On active locale change, Runtime refreshes the visible step for its phase — LINE for `PresentingLine`/`AwaitingInput` (D13.4) and CHOICES for `AwaitingChoice` — preserving all traversal state; during `AwaitingChoice` it also refreshes the co-visible prompting LINE via `refresh_line_text` when known (ADR-023); `ExecutingCommand` does not restart; `WAIT`/`COMMAND` need no refresh (D28.11). LINE refresh re-resolves delegated interpolation values (D28.15).
- **Resume (ADR-022 D28.13):** `resume()` rebuilds localized delivery from compiled data using the **active locale at resume time**; snapshots store coordinates only, never localized strings or the active locale.
- **Catalog / locale ownership (ADR-022 D28.7):** The game / Godot project authors and registers translation catalogs and selects the active locale; Runtime consumes the active locale and never registers catalogs or owns locale policy.

---

## Related documents

- [01-architecture-overview.md](01-architecture-overview.md) — Phases and API summary
- [03-compilation-and-data.md](03-compilation-and-data.md) — Data schemas
- [decisions/006-runtime-execution.md](decisions/006-runtime-execution.md) — ADR
- [decisions/009-game-integration.md](decisions/009-game-integration.md) — ADR
- [decisions/010-ui-and-presenter.md](decisions/010-ui-and-presenter.md) — ADR
- [06-product-structure.md](06-product-structure.md) — Runtime vs Presentation
- [decisions/014-product-structure-and-presentation.md](decisions/014-product-structure-and-presentation.md) — ADR
- [decisions/020-localization-architecture.md](decisions/020-localization-architecture.md) — Localization subsystem
- [decisions/022-localized-runtime-delivery-locale-switching.md](decisions/022-localized-runtime-delivery-locale-switching.md) — Runtime delivery and locale switching
