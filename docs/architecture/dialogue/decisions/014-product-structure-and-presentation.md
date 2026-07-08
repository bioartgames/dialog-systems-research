# ADR 014: Product Structure and Presentation Subsystem

**Status:** Accepted  
**Date:** 2026-07-07  
**Decisions:** D20.1–D20.6  
**Amends:** D11.1 (clarification), D1.6 (clarification), subsystem ownership diagram

## Context

ADR-010 (D11.1) stated that the framework does not ship production UI and that every game project builds its own presenter scene. That decision reflected **v1 shipping scope** and **runtime/UI separation** inspired by Dialogue Manager (engine vs balloon), not a permanent ban on reusable dialogue presentation technology within the Dialogue Framework product.

The repository now codifies a two-subsystem product model:

- **Runtime** — headless dialogue execution (traversal, phases, DTOs, contracts).
- **Presentation** — dialogue-specific presentation policy and reusable implementations.

Ui React remains a separate generic UI addon. Games integrate Runtime, Presentation, and game-specific code.

## Core invariants (normative)

These two rules are the architectural essence of this decision. All other rules in this ADR elaborate them; they SHALL NOT be weakened.

1. **Runtime SHALL NOT import Presentation.** The Runtime subsystem (`runtime/`) must not reference, preload, or depend on code, scenes, or resources under `presentation/`. Runtime remains headless and presentation-agnostic.

2. **Presentation MAY depend on Runtime but SHALL remain optional to adopt.** The Presentation subsystem (`presentation/`) may import Runtime and data types. Games and integrators are not required to use Presentation reference implementations; a custom `IDialoguePresenter` or a minimal test double satisfies the Runtime contract.

## Decision

1. **Dialogue Framework product structure (D20.1)** — `addons/dialogue_framework/` is the Dialogue Framework **product**, composed of:
   - `runtime/` — execution engine (always required).
   - `compiler/` — compile-at-import pipeline.
   - `data/` — DTOs, resources, enums.
   - `presentation/` — dialogue presentation subsystem (reference implementations, scenes, settings; optional to adopt per invariant 2).
   - `tests/`, `docs/` — verification and integration guides.

2. **Runtime remains presentation-agnostic (D20.2)** — Implements invariant 1: `runtime/` SHALL NOT import `presentation/`. Runtime must not instantiate presentation scenes, reference Godot `Control` nodes for dialogue HUD, or depend on Ui React. `DialogueRunner` has no UI or scene tree references (D1.2, D1.6).

3. **Presentation owns dialogue presentation technology (D20.3)** — The Presentation subsystem owns `IDialoguePresenter` implementations, typewriter/reveal policy, tag interpretation (`#voice`, `#time`), choice/speaker/portrait presentation (when ADRs permit), dialogue layouts, themes, presentation resources/scenes, and accessibility behavior for dialogue UI. Presentation depends on Runtime types and contracts only.

4. **Runtime owns presentation contracts only (D20.4)** — `IDialoguePresenter` and `ConversationStep` remain in Runtime/data. Runtime stores tags on steps but does not interpret them at runtime. `ConversationController` holds an `IDialoguePresenter` reference and calls `present()` / `dismiss()`; it does not implement presentation.

5. **Ui React is optional infrastructure (D20.5)** — Presentation may use Ui React for bindings and animations. Presentation must work with native Godot UI alone. Dialogue Framework and Runtime must never depend on Ui React. Ui React must never depend on Dialogue Framework or dialogue concepts.

6. **Game integration boundary (D20.6)** — Games implement `GameContext`, register commands, orchestrate conversations, route input, and **wire** an `IDialoguePresenter` instance into `ConversationController.start()`. Games are not expected to author all presentation technology from scratch; they may use Presentation reference implementations or custom presenters.

### Normative dependency graph

```
                Runtime
                   ▲
                   │
             Presentation
              ▲         ▲
              │         │
     Native Godot UI   Ui React (optional)

Game → Runtime
Game → Presentation (wire presenter, optional overrides)
```

**Allowed:** Presentation → Runtime; Presentation → native Godot UI; Presentation → Ui React (optional); Game → Runtime; Game → Presentation.

**Forbidden:** Runtime → Presentation; Runtime → Ui React; Runtime → Godot UI scenes/Controls for dialogue HUD; Ui React → Runtime; Ui React → dialogue concepts.

### Amendment to D11.1

**Previous (v1 wording):** Framework does not ship production UI.

**Clarified:** The **Runtime subsystem** does not ship production UI. The **Presentation subsystem** provides reusable dialogue presentation implementations. Adoption of Presentation reference assets is optional (invariant 2); custom `IDialoguePresenter` implementations remain valid.

## Consequences

- Package layout documentation and structure tests include `presentation/`.
- Headless GUT tests continue to target `runtime/`, `compiler/`, and `data/` without Presentation scenes.
- Presentation integration tests are separate from Runtime headless tests.
- ADR-010 presenter responsibilities (typewriter, tags, BBCode policy) apply to the **Presentation subsystem**, not to game demo code by default.
- Games using only Runtime bring any `IDialoguePresenter` (including minimal test doubles).

## References

- [00-project-goals.md](../00-project-goals.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/010-ui-and-presenter.md](010-ui-and-presenter.md)
- [decisions/001-philosophy-and-scope.md](001-philosophy-and-scope.md)
