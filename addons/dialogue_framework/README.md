# Dialogue Framework

Custom Godot 4 dialogue addon for **MegaMan Legends–style 3D action RPG** conversations. Text-first authoring (`.dlg`), compile-at-import, and a thin runtime facade the game owns.

**Architecture source of truth:** [`docs/architecture/dialogue/`](../../docs/architecture/dialogue/)

---

## Setup

1. Enable the **Dialogue Framework** plugin in **Project → Project Settings → Plugins**.
2. On enable, the plugin registers the **`ConversationController`** autoload (D1.5, D2.1) pointing at `runtime/conversation_controller.gd`.
3. Optional: set manifest paths under **Project Settings → Dialogue Framework** (see below).
4. Author `.dlg` files in an external editor; Godot reimports them to `CompiledDialogue` `.tres` resources (D1.3).

---

## ProjectSettings keys

Registered by `DialogueFrameworkProjectSettings` when the plugin enters the editor tree:

| Key | Type | Purpose |
|-----|------|---------|
| `dialogue_framework/flag_manifest_path` | `*.tres` | `FlagManifest` for compile-time flag / `{brace}` validation |
| `dialogue_framework/command_manifest_path` | `*.tres` | `CommandManifest` for compile-time game `@command` validation |
| `dialogue_framework/compile_processor_path` | `*.gd` (advanced) | Optional `DialogueCompileProcessor` hook |

All default to empty. Built-in `@commands` compile without a command manifest; strict validation modes require manifests per ADR-005.

---

## Integration contracts (game implements)

| Contract | Location | Responsibility |
|----------|----------|----------------|
| **`GameContext`** | `runtime/game_context.gd` (abstract) | Flags, items, quests, `{brace}` display values — **game save is authoritative** (D1.1) |
| **`IDialoguePresenter`** | `runtime/i_dialogue_presenter.gd` | Render `ConversationStep`; call `notify_presentation_finished()` for `LINE` steps (D11.1) |
| **`FlagManifest`** | `data/flag_manifest.gd` | Declare valid flags for the compiler |
| **`CommandManifest`** | `data/command_manifest.gd` | Declare valid game `@command` names for the compiler |

**Addon guides:**

- [docs/game_presenter.md](docs/game_presenter.md) — Presenter contract and v1 UI constraints
- [docs/game_command_integration.md](docs/game_command_integration.md) — `CommandRegistry` patterns
- [docs/extension_points.md](docs/extension_points.md) — v1 extension points and closed `LineKind` set

**Runtime entry:** `ConversationController.start(compiled, entry, context, presenter)` — see [01-architecture-overview.md](../../docs/architecture/dialogue/01-architecture-overview.md).

---

## Architecture traceability index

### Core documents

| Document | Topics |
|----------|--------|
| [00-project-goals.md](../../docs/architecture/dialogue/00-project-goals.md) | Philosophy D1.1–D1.6, v1 non-goals |
| [01-architecture-overview.md](../../docs/architecture/dialogue/01-architecture-overview.md) | Controller → Runner → DTO layering (D1.2) |
| [02-authoring-format.md](../../docs/architecture/dialogue/02-authoring-format.md) | `.dlg` syntax |
| [03-compilation-and-data.md](../../docs/architecture/dialogue/03-compilation-and-data.md) | `CompiledDialogue`, import pipeline (D1.3) |
| [04-runtime-and-integration.md](../../docs/architecture/dialogue/04-runtime-and-integration.md) | Execution, commands, save/resume |
| [05-open-questions.md](../../docs/architecture/dialogue/05-open-questions.md) | Deferred editor / VN features (D19.x) |

### Architecture Decision Records

| ADR | Decision cluster |
|-----|------------------|
| [001-philosophy-and-scope.md](../../docs/architecture/dialogue/decisions/001-philosophy-and-scope.md) | D1.1–D1.6 |
| [002-runtime-architecture.md](../../docs/architecture/dialogue/decisions/002-runtime-architecture.md) | Phases, controller API |
| [003-data-model.md](../../docs/architecture/dialogue/decisions/003-data-model.md) | `CompiledDialogue` / `CompiledLine` |
| [004-authoring-format.md](../../docs/architecture/dialogue/decisions/004-authoring-format.md) | `.dlg` format |
| [005-compilation-pipeline.md](../../docs/architecture/dialogue/decisions/005-compilation-pipeline.md) | Compiler stages, import |
| [006-runtime-execution.md](../../docs/architecture/dialogue/decisions/006-runtime-execution.md) | Step delivery, commands |
| [007-commands.md](../../docs/architecture/dialogue/decisions/007-commands.md) | Built-in vs game commands |
| [008-conditions-and-state.md](../../docs/architecture/dialogue/decisions/008-conditions-and-state.md) | `GameContext`, no variable store (D9.1) |
| [009-game-integration.md](../../docs/architecture/dialogue/decisions/009-game-integration.md) | Manifests, handlers |
| [010-ui-and-presenter.md](../../docs/architecture/dialogue/decisions/010-ui-and-presenter.md) | `IDialoguePresenter` |
| [011-save-localization-debug.md](../../docs/architecture/dialogue/decisions/011-save-localization-debug.md) | Snapshots, i18n, debug |
| [012-validation-tooling-testing.md](../../docs/architecture/dialogue/decisions/012-validation-tooling-testing.md) | GUT harness, golden snapshots |
| [013-future-editor.md](../../docs/architecture/dialogue/decisions/013-future-editor.md) | Visual editor deferred |

### Package layout

```
addons/dialogue_framework/
  compiler/     # .dlg → CompiledDialogue (editor / dev test API only)
  data/         # Resources, DTOs, enums
  runtime/      # ConversationController, DialogueRunner, evaluators
  tests/        # GUT unit + integration tests
  docs/         # Game integration guides (this README links ADRs + guides)
```

---

## Testing

Headless GUT suite:

```bash
godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://addons/dialogue_framework/tests/unit -ginclude_subdirs -gexit
```

Tests cover compiler validation, runner traversal, controller phases, golden compile snapshots, and v1 scope verification (D1.x, D16.x, D19.x).
