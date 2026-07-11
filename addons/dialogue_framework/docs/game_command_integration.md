# Game Command Integration Patterns

The dialogue framework ships **built-in commands only** (`@wait`, `@set_flag`, `@emit`). Shops, cutscenes, quests, inventory mutations, camera moves, and character animations are **game responsibilities** registered at runtime via `CommandRegistry` (D10.2–D10.6, ADR-009).

Architecture references: [ADR-009 Game Integration](../../../../docs/architecture/dialogue/decisions/009-game-integration.md), [04-runtime-and-integration.md](../../../../docs/architecture/dialogue/04-runtime-and-integration.md).

---

## Prerequisites (D9.6, D10.6)

Every game `@command` must satisfy **both**:

1. **`CommandManifest`** — declare the command name so `.dlg` import / `compile_string()` succeeds.
2. **`CommandRegistry`** — register a runtime handler before `ConversationController.start()`.

Built-in commands (`wait`, `set_flag`, `emit`) are always valid and need no manifest entry.

Example manifest resource (`CommandManifest.commands`):

```gdscript
# res://game/dialogue/game_commands.tres
commands = PackedStringArray([
    "open_shop", "cutscene", "start_quest", "complete_quest",
    "give_item", "remove_item", "camera", "anim",
])
```

Point ProjectSettings `dialogue_framework/command_manifest_path` at that resource (see `DialogueFrameworkProjectSettings`).

Register handlers during game boot (before any conversation):

```gdscript
const ReferenceGameCommandHandlers = preload(
    "res://addons/dialogue_framework/tests/helpers/reference_game_command_handlers.gd"
)

func _register_dialogue_commands() -> void:
    ReferenceGameCommandHandlers.register_open_shop_handler(_on_open_shop)
    # ... see tests/helpers/reference_game_command_handlers.gd
```

The `ReferenceGameCommandHandlers` class lives under **`tests/helpers/`** as copy-paste reference code — it is **not** part of the shipped runtime.

---

## Pattern 1 — `@open_shop` (D10.2)

**Intent:** End or pause the conversation and switch to shop game mode. The framework does not open UI or inventory screens.

**Authoring:**

```text
~ shop_exit
@open_shop general_store
=> END
```

**Game handler responsibilities:**

1. Hide dialogue UI (presenter `dismiss()` is called automatically before game-registered `COMMAND` steps when advancing from a visible line; built-in `@set_flag` and `@emit` do **not** dismiss).
2. Call `ConversationController.cancel()` if the dialogue should not resume on the same line.
3. Transition to your shop scene / game mode with the shop id from args.

See `test_reference_game_command_patterns.gd` → `test_open_shop_reference_pattern_cancels_conversation`.

---

## Pattern 2 — `@cutscene` (D10.3)

**Intent:** Run an async cutscene while dialogue UI stays hidden. Requires a game `CutsceneDirector` (or equivalent).

**Authoring:**

```text
@cutscene intro_roll_meeting
Roll: That was quite an entrance.
```

**Game handler responsibilities:**

1. Register an **async** handler (`await` inside) so `ConversationController` waits before auto-advancing (D6.6).
2. Hide or keep dismissed any dialogue balloon during playback.
3. Return when the cutscene finishes.

See `test_reference_game_command_patterns.gd` → `test_cutscene_reference_pattern_is_async_before_next_line`.

---

## Pattern 3 — Quest commands (D10.4)

**Intent:** Mutate quest state through `GameContext` methods. The framework evaluates `get_quest_state()` in conditions; progression commands are game-registered.

**Authoring:**

```text
@start_quest find_the_key
@complete_quest find_the_key
```

**Game handler responsibilities:**

1. Implement `start_quest` / `complete_quest` on your `GameContext` subclass.
2. Register handlers that delegate to those methods (see `ReferenceGameCommandHandlers.register_quest_handlers()`).
3. Use `get_quest_state("quest_id")` in `.dlg` conditions — no extra command required for reads.

---

## Pattern 4 — Inventory commands (D10.5)

**Intent:** `has_item()` is evaluated at step-build time via `ConditionEvaluator`. Item grants/removals use game `@commands`.

**Authoring:**

```text
if has_item("brass_key")
    Roll: You already have the key.
else
    @give_item brass_key 1
    Roll: Take this spare key.
endif
```

**Game handler responsibilities:**

1. Implement `has_item`, `give_item`, `remove_item` on `GameContext`.
2. Register `give_item` / `remove_item` command handlers.
3. Keep item ids consistent between conditions and commands.

---

## Pattern 5 — `@camera` and `@anim` (D10.6)

**Intent:** 3D presentation hooks — framework is agnostic to scene tree layout, tweens, or AnimationPlayer wiring.

**Authoring:**

```text
@camera pan_to roll 1.5
@anim wave 2
```

**Game handler responsibilities:**

1. Parse `PackedStringArray` args in your handler (pre-tokenized at compile time).
2. Drive camera rig / `AnimationPlayer` in game code.
3. Use sync handlers for instantaneous moves; use `await` for timed sequences (same as cutscene pattern).

The framework does **not** implement camera or animation systems.

---

## What the framework does not provide

- Shop UI, inventory screens, or economy logic
- Cutscene director, timeline playback, or scene streaming
- Camera rigs, animation trees, or 3D actor control
- Quest graph or journal UI

Implement these in game code and expose them only through `CommandRegistry` handlers plus `GameContext` state.

---

## Reference tests

| Integration type | Test |
|------------------|------|
| `@open_shop` | `test_reference_game_command_patterns.gd` |
| `@cutscene` | `test_reference_game_command_patterns.gd` |
| Quest commands | `test_reference_game_command_patterns.gd` |
| Inventory commands | `test_reference_game_command_patterns.gd` |
| `@camera` / `@anim` | `test_reference_game_command_patterns.gd` |
| Manifest required (D9.6) | `test_reference_game_command_patterns.gd` |

Fixture manifest: `tests/fixtures/reference_game_command_manifest.tres`.

---

## Related documentation

- [game_presenter.md](game_presenter.md) — UI presenter contract
- [02-authoring-format.md](../../../../docs/architecture/dialogue/02-authoring-format.md) — `@command` syntax
