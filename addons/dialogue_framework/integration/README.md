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

**IK-0–IK-3** surfaces present (`ResourceGameContext`, `CommandBridge` + registrar, `CompiledDialogueLoader`). Remaining: IK-4 (starter), kit GUT package, adoption docs.

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

## Related

- Addon overview: [../README.md](../README.md)
- Runtime contracts: [../docs/game_presenter.md](../docs/game_presenter.md), [../docs/game_command_integration.md](../docs/game_command_integration.md)
