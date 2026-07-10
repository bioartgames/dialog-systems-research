# Framework Extension Points and v1 Constraints

This addon exposes a small, explicit set of **extension hooks** (D17.1). v1 does **not** support custom compiled line kinds or runtime graph extensions (D17.2).

**Product structure:** Runtime defines contracts; Presentation provides reusable `IDialoguePresenter` implementations. See [ADR-014](../../../../docs/architecture/dialogue/decisions/014-product-structure-and-presentation.md).

Architecture references: [ADR-012 Validation, Tooling and Testing](../../../../docs/architecture/dialogue/decisions/012-validation-tooling-testing.md), [03-compilation-and-data.md](../../../../docs/architecture/dialogue/03-compilation-and-data.md).

---

## Extension point summary (D17.1)

| Extension | When to implement | Owner | Framework contract |
|-----------|-------------------|-------|-------------------|
| **GameContext** | Always — one subclass (or per-NPC instance) per game | **Game** | Abstract methods for flags, items, quests, display values, bindings (D10.1) |
| **`IDialoguePresenter` interface** | Always required at integration boundary | **Runtime** | `present(step)`, `dismiss()` only (D11.2) |
| **`IDialoguePresenter` implementation** | Always — production dialogue UI | **Presentation** or **Game** (custom) | Implements Runtime contract |
| **CommandRegistry** | Before `ConversationController.start()` | **Game** | Register `@command` handlers; built-ins pre-registered (D7.1) |
| **DialogueCompileProcessor** | Optional advanced compile hook | **Game** | `_preprocess_line` / `_post_process_line` via ProjectSettings path (D17.3) |

The **Runtime** subsystem owns traversal (`DialogueRunner`), phases (`ConversationController`), and compiled schemas. Games extend behavior through the hooks above — not by subclassing the runner or mutating `CompiledLine` shape at runtime.

---

## 1. GameContext

**Purpose:** Inject game-authoritative state into conditions, brace interpolation, and built-in `@set_flag`.

**Contract:** `addons/dialogue_framework/runtime/game_context.gd`

| Method | Used by |
|--------|---------|
| `get_flag` / `set_flag` | `ConditionEvaluator`, `@set_flag`, `{brace}` keys |
| `has_item` | `ConditionEvaluator` |
| `give_item` / `remove_item` | Game-registered `@commands` (D10.5) |
| `get_quest_state` / `start_quest` / `complete_quest` | Conditions and quest commands (D10.4) |
| `get_display_value` | `{brace}` interpolation in line text |
| `get_binding` | Per-conversation bindings (`npc_id`, etc.) |

**Integration:**

```gdscript
var context: GameContext = MyGameContext.new()
ConversationController.start(compiled, "start", context, presenter)
```

`ConditionEvaluator` may **only** call the methods above plus literal operators (D8.2). Do not add parallel flag stores inside the dialogue addon.

**Reference:** `tests/helpers/mock_game_context.gd`, `tests/unit/test_game_context.gd`.

---

## 2. IDialoguePresenter

### Runtime contract

**Purpose:** Boundary between execution and display.

**Contract:** `addons/dialogue_framework/runtime/i_dialogue_presenter.gd`

```gdscript
func present(step: ConversationStep) -> void
func dismiss() -> void
```

### Presentation implementations

**Purpose:** Render `LINE` and `CHOICES` steps; hide UI on `dismiss()`.

**Location:** `addons/dialogue_framework/presentation/` (reference implementations) or game-specific overrides.

**Rules:**

- No `on_choice` on the interface — wire choice UI to `ConversationController.choose(index)` using each option's `index` field (D11.2).
- Call `ConversationController.notify_presentation_finished()` when typewriter, `#voice`, or `#time` completes (D11.5, D11.7, D13.5).
- Do **not** call `DialogueRunner`, read `CompiledDialogue`, or advance the conversation from the presenter.

**Detailed guide:** [game_presenter.md](game_presenter.md).

---

## 3. CommandRegistry

**Purpose:** Dispatch game `@commands` at runtime after compile-time manifest validation.

**Contract:** `addons/dialogue_framework/runtime/command_registry.gd`

```gdscript
CommandRegistry.register("camera", func(args: PackedStringArray) -> void:
    # may await
)
await CommandRegistry.dispatch("camera", args_tokens)
```

**Rules:**

- Register handlers in game boot (`_ready()`), **before** any `ConversationController.start()`.
- Declare command names in `CommandManifest` so `.dlg` import succeeds (D9.6).
- Built-ins (`wait`, `set_flag`, `emit`) are valid without manifest entries.
- Duplicate registration → `push_error`.

**Detailed guide:** [game_command_integration.md](game_command_integration.md).

---

## 4. DialogueCompileProcessor (optional, D17.3)

**Purpose:** Optional compile-time line preprocessing or post-processing without forking the compiler.

**Configuration:** ProjectSettings `dialogue_framework/compile_processor_path` → a `Script` resource path (`DialogueFrameworkProjectSettings`).

**Script contract** (instance methods on a `RefCounted` or `Node` script):

```gdscript
func _preprocess_line(raw: String) -> String:
    return raw  # transformed source line before parsers run

func _post_process_line(line: Dictionary) -> void:
    pass  # mutate compiled line dict in place (must stay schema-valid)
```

Leave the setting empty to skip the hook. If the path is set but invalid, resolution logs an error and returns null.

**Reference:** `tests/fixtures/mock_compile_processor.gd`, `tests/unit/test_project_settings.gd`.

**Caution:** `_post_process_line` must not add fields outside the `CompiledLine` schema or introduce new `LineKind` values (D17.2, D19.3).

---

## v1 line type constraints (D17.2)

The compiled graph uses a **closed** `LineKind` enum. v1 does **not** support custom line types, plugins that add new `kind` values, or author-defined node types in `.dlg`.

### Allowed `LineKind` values

| Kind | Role |
|------|------|
| `TITLE` | Entry label (`~ title`) |
| `LINE` | Speaker dialogue (yielded to presenter) |
| `CONDITION` | `if` / `elif` / `else` branch header (skipped at yield) |
| `CHOICE` | Choice row (grouped into `CHOICES` step) |
| `COMMAND` | `@command` line |
| `GOTO` | `=> title` / `=> END` |
| `END` | Terminal node |

Source of truth: `addons/dialogue_framework/data/line_kind.gd`.

Automated check: `tests/unit/test_line_kind.gd` asserts enum keys match architecture.

### What is not allowed in v1

- New `LineKind` enum members without a **future ADR** and format version bump.
- Runtime insertion of unknown `kind` strings into `CompiledDialogue.lines`.
- Editor-only metadata fields on `CompiledLine` (see D19.3; validated by `CompiledLine.validate()`).
- `#portrait` tag or a portrait field on `ConversationStep` (D11.4).

To add a new line category (e.g. embedded cutscene nodes), plan a **format_version** increment, compiler changes, runner yield rules, and a new ADR — not an ad hoc game-side extension.

---

## Versioning and semver (D17.4)

Two version concepts apply:

| Version | Location | Meaning |
|---------|----------|---------|
| **Addon semver** | `addons/dialogue_framework/plugin.cfg` → `version=` | Package release tag for the Godot addon (e.g. `0.1.0`). Follow [semantic versioning](https://semver.org/) for releases. |
| **Format / compiler integers** | `DialogueFrameworkVersions.FORMAT_VERSION`, `COMPILER_VERSION` | Written into each `CompiledDialogue` resource (D3.1, D5.2). Bump when compiled **schema** or **compiler output** changes incompatibly. |

**Policy:**

- **Patch** addon semver: bug fixes, docs, tests — no schema change.
- **Minor** addon semver: backward-compatible features (new built-in commands, new optional ProjectSettings) — usually no `FORMAT_VERSION` bump.
- **Major** addon semver: breaking API or compiled format changes — increment `FORMAT_VERSION` and document migration.

`tests/unit/test_framework_versions.gd` verifies `plugin.cfg` uses semver and documents current format/compiler constants.

Re-import `.dlg` files after addon upgrades that bump `COMPILER_VERSION` so `.tres` outputs stay consistent.

**Compiler v2 (`COMPILER_VERSION` 2):** adds condition-block exit wiring (D5.11) — if/elif/else branch bodies no longer fall through into sibling branch bodies at runtime. Re-import all `.dlg` assets after upgrading.

---

## Related documentation

- [game_presenter.md](game_presenter.md) — Presenter contract and Presentation responsibilities
- [game_command_integration.md](game_command_integration.md) — CommandRegistry patterns
- [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md) — Runtime vs Presentation
- [02-authoring-format.md](../../../../docs/architecture/dialogue/02-authoring-format.md) — `.dlg` syntax and tags
- [05-open-questions.md](../../../../docs/architecture/dialogue/05-open-questions.md) — Deferred features (visual editor, custom line types)
