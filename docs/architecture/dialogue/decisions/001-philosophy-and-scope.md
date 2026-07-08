# ADR 001: Philosophy and Scope

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D1.1–D1.6

## Context

Building a custom dialogue framework for a MegaMan Legends–style 3D action RPG. Research on Dialogic 2 and Dialogue Manager showed both plugins exceed action-RPG needs and differ on state ownership and UI coupling.

## Decision

1. **Game-authoritative state** — Game save owns flags/items/quests; no dialogue variable store (D1.1).
2. **Layered interpreter** — `ConversationController` → `DialogueRunner` → `ConversationStep` DTO (D1.2).
3. **Compile at import** — `.dlg` → `CompiledDialogue` `.tres` via `EditorImportPlugin` (D1.3).
4. **Action-RPG v1 scope** — YAGNI; exclude VN features (D1.4).
5. **Autoload facade** — Single `ConversationController` autoload (D1.5).
6. **Testable core** — Runner/evaluator testable without scene tree; games wire `IDialoguePresenter`; Presentation subsystem may supply reference implementations (D1.6, amended by ADR-014).

## Consequences

- Game teams must implement `GameContext` and wire an `IDialoguePresenter` into Runtime.
- No runtime `.dlg` parsing in production.
- Runtime subsystem stays smaller than reference plugins; Presentation is a separate subsystem within the product (ADR-014).

## References

- [00-project-goals.md](../00-project-goals.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
- [Research summary](../research/00-research-summary.md)
