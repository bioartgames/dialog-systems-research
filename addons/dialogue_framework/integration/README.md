# Integration Kit (optional)

**Architecture:** [ADR-024](../../../../docs/architecture/dialogue/decisions/024-optional-game-integration-kit.md) · [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md)  
**Implementation plan:** [adr-024-integration-kit-implementation-plan.md](../../../../docs/architecture/dialogue/planning/adr-024-integration-kit-implementation-plan.md) (`IK-*`)

This folder is the optional **Game Integration kit** of the Dialogue Framework product. It is **not** part of Runtime or Presentation.

## Purpose

Editor-first surfaces that configure the **game boundary**:

- Conversation starter Node
- Resource / dictionary-backed `GameContext` (reference implementation — **not** authoritative save)
- Command bridge Resource + registrar
- Thin `CompiledDialogue` load helper
- Adoption docs (Godot-native translation workflow as primary i18n story)

Adoption is **optional**. Games may keep custom `GameContext`, manual `CommandRegistry` registration, and bespoke orchestration.

## Normative invariants (ADR-024 D30.2)

1. **Runtime SHALL NOT import Integration** (or Presentation).
2. **Integration MAY depend on Runtime and `data/` only.**
3. **Integration SHALL NOT import `presentation/`** or Ui React. Presenters are wired by `NodePath` / `IDialoguePresenter`.
4. Kit surfaces must not own translation catalogs, locale policy, or authoritative game save data.

## Status

**IK-0–IK-7** complete. Showcase demo uses kit for start/context/commands; panel, smoke harness, locale toggle, and JSON catalogs remain demo-owned (D30.11 dual-path).

**Full adoption guide:** [docs/integration_kit_adoption.md](../docs/integration_kit_adoption.md)

### Testing (IK-5)

| Suite | Path | Required for Runtime purity? |
|-------|------|------------------------------|
| Runtime / compiler / data (+ boundary) | `tests/unit/` | **Yes** (default CI headless) |
| Integration kit surfaces + smoke | `tests/integration_kit/` | **No** — optional adoption verification |

Kit coverage: `ResourceGameContext`, `CommandBridge`, `CompiledDialogueLoader`, `ConversationStarter`, plus `test_integration_kit_smoke` (start/cancel + custom-context replaceability). Boundary purity remains in `tests/unit/test_integration_boundary_enforcement.gd`.


## ResourceGameContext (IK-1)

| Surface | Role |
|---------|------|
| `ResourceGameContext` | `Resource` with `@export` dictionaries (`flags`, `items`, `quest_states`, `display_values`, `bindings`) |
| `make_context()` | Returns a `GameContext` that read/writes those dictionaries |

**Not authoritative save (D1.1):** Treat this Resource as integration configuration / session scratch. The game's save system remains the source of truth for flags, items, and quests. Subclass `ResourceGameContext` or replace it with a custom `GameContext` when you need save-backed or world-specific behavior (D30.6).

Create a `.tres` in the Inspector (or assign an inline sub-resource on a future Conversation Starter) — no custom script required for the dictionary happy path.

## CommandBridge (IK-2)

| Surface | Role |
|---------|------|
| `CommandBridge` | `Resource` with `@export` bools selecting which `@commands` to register; `register_all(...)` wires them |
| `CommandBridgeRegistrar.register_all(...)` | Thin static entry that forwards to `CommandBridge.register_all` (uses `CommandRegistry.register` only) |

**Context commands** (when enabled): `start_quest`, `complete_quest`, `give_item`, `remove_item` → `GameContext` methods.

**Game-mode hooks** (when enabled): `open_shop`, `cutscene`, `camera`, `anim` → injected `Callable`s only (no kit shop/cutscene/camera/anim implementations). Pass hooks at register time; invalid Callables are no-ops on dispatch.

Duplicate command names follow existing `CommandRegistry` semantics (`push_error`, keep the first handler). Games may ignore the bridge and call `CommandRegistry.register` directly (D30.6).

## CompiledDialogueLoader (IK-3)

| Surface | Role |
|---------|------|
| `CompiledDialogueLoader.load_compiled(path)` | Load an imported `.dlg` or a saved `CompiledDialogue` resource |
| `load_imported(path)` | Alias with the same result shape (showcase naming) |
| `dlg_import_is_valid(dlg_path)` | Check `.dlg.import` remapping without loading |

Result dictionary: `{ compiled, source, errors }` — `compiled` is a `CompiledDialogue` on success, otherwise `null` with actionable `errors`. This helper does **not** compile at runtime; import / authored resources remain the source of truth.

## ConversationStarter (IK-4)

| Surface | Role |
|---------|------|
| `ConversationStarter` | Node with Inspector exports for dialogue, entry, presenter path, kit context, optional bridge |
| `start_conversation()` / `cancel_conversation()` | Call existing `ConversationController.start` / `cancel` only |
| `set_context(GameContext)` | Inject a custom context (replaces `context_resource` for this starter) |

**Presenter:** `presenter_path` must point at an `IDialoguePresenter` in the scene tree — no `presentation/` import.

**Dialogue source:** prefer `@export compiled_dialogue`, or set `dialogue_path` to an imported `.dlg` / `CompiledDialogue` path (uses `CompiledDialogueLoader`).

**Commands:** when `command_bridge` is set, registration runs once before the first start (and on `_ready` if `register_commands_on_ready`). Set `on_open_shop` / `on_cutscene` / `on_camera` / `on_anim` Callables from code for game-mode hooks.

## Related

- **Adoption guide:** [../docs/integration_kit_adoption.md](../docs/integration_kit_adoption.md)
- Addon overview: [../README.md](../README.md)
- Runtime contracts: [../docs/game_presenter.md](../docs/game_presenter.md), [../docs/game_command_integration.md](../docs/game_command_integration.md)
