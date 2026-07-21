# ADR 014: Product Structure and Presentation Subsystem

**Status:** Accepted (amended by ADR-024)  
**Date:** 2026-07-07  
**Decisions:** D20.1–D20.6  
**Amends:** D11.1 (clarification), D1.6 (clarification), subsystem ownership diagram  
**Amended by:** ADR-024 (optional `integration/` kit; D20.1 / D20.6 clarification)

## Context

ADR-010 (D11.1) stated that the framework does not ship production UI and that every game project builds its own presenter scene. That decision reflected **v1 shipping scope** and **runtime/UI separation** inspired by Dialogue Manager (engine vs balloon), not a permanent ban on reusable dialogue presentation technology within the Dialogue Framework product.

The repository now codifies a product model with:

- **Runtime** — headless dialogue execution (traversal, phases, DTOs, contracts).
- **Presentation** — dialogue-specific presentation policy and reusable implementations (optional).
- **Integration** — optional editor-first game-boundary kit (ADR-024).

Ui React remains a separate generic UI addon. Games integrate Runtime, and optionally Presentation and/or Integration, plus game-specific code.

## Core invariants (normative)

These rules are the architectural essence of this decision. All other rules in this ADR elaborate them; they SHALL NOT be weakened.

1. **Runtime SHALL NOT import Presentation.** The Runtime subsystem (`runtime/`) must not reference, preload, or depend on code, scenes, or resources under `presentation/`. Runtime remains headless and presentation-agnostic.

2. **Presentation MAY depend on Runtime but SHALL remain optional to adopt.** The Presentation subsystem (`presentation/`) may import Runtime and data types. Games and integrators are not required to use Presentation reference implementations; a custom `IDialoguePresenter` or a minimal test double satisfies the Runtime contract.

3. **Runtime SHALL NOT import Integration** (ADR-024 D30.2). Integration may depend on Runtime and `data/` only; it SHALL NOT import `presentation/`; and it SHALL remain optional to adopt.

## Decision

1. **Dialogue Framework product structure (D20.1)** — `addons/dialogue_framework/` is the Dialogue Framework **product**, composed of:
   - `runtime/` — execution engine (always required).
   - `compiler/` — compile-at-import pipeline.
   - `data/` — DTOs, resources, enums.
   - `presentation/` — dialogue presentation subsystem (reference implementations, scenes, settings; optional to adopt per invariant 2).
   - `integration/` — optional Game Integration kit (ADR-024; conversation starter, reference `GameContext`, command bridge; optional to adopt per invariant 3).
   - `tests/`, `docs/` — verification and integration guides.

2. **Runtime remains presentation-agnostic (D20.2)** — Implements invariant 1: `runtime/` SHALL NOT import `presentation/`. Runtime must not instantiate presentation scenes, reference Godot `Control` nodes for dialogue HUD, or depend on Ui React. `DialogueRunner` has no UI or scene tree references (D1.2, D1.6). **Amended by ADR-024:** Runtime also SHALL NOT import `integration/`.

3. **Presentation owns dialogue presentation technology (D20.3)** — The Presentation subsystem owns `IDialoguePresenter` implementations, typewriter/reveal policy, tag interpretation (`#voice`, `#time`), choice/speaker/portrait presentation (when ADRs permit), dialogue layouts, themes, presentation resources/scenes, and accessibility behavior for dialogue UI. Presentation depends on Runtime types and contracts only.

4. **Runtime owns presentation contracts only (D20.4)** — `IDialoguePresenter` and `ConversationStep` remain in Runtime/data. Runtime stores tags on steps but does not interpret them at runtime. `ConversationController` holds an `IDialoguePresenter` reference and calls `present()` / `dismiss()`; it does not implement presentation.

5. **Ui React is optional infrastructure (D20.5)** — Presentation may use Ui React for bindings and animations. Presentation must work with native Godot UI alone. Dialogue Framework and Runtime must never depend on Ui React. Ui React must never depend on Dialogue Framework or dialogue concepts. Integration must not depend on Ui React (ADR-024).

6. **Game integration boundary (D20.6)** — Games remain responsible for authoritative game state, when conversations run, and how presenters are wired. They **may** implement `GameContext`, register commands, and orchestrate conversations entirely in game code, **or** adopt optional Integration kit surfaces (ADR-024) for editor-first configuration of those same responsibilities. Games are not expected to author all presentation technology from scratch; they may use Presentation reference implementations or custom presenters. Integration wires a presenter; it does not implement dialogue HUD.

### Normative dependency graph

```
                Runtime
               ▲       ▲
               │       │
        Presentation   Integration
              ▲         ▲
              │         │
     Native Godot UI   (Game wires both as needed)
              ▲
              │
        Ui React (optional; Presentation only)

Game → Runtime
Game → Presentation (wire presenter, optional overrides)
Game → Integration (optional kit surfaces)
```

**Allowed:** Presentation → Runtime; Presentation → native Godot UI; Presentation → Ui React (optional); Integration → Runtime / `data/`; Game → Runtime; Game → Presentation; Game → Integration.

**Forbidden:** Runtime → Presentation; Runtime → Integration; Runtime → Ui React; Runtime → Godot UI scenes/Controls for dialogue HUD; Integration → Presentation; Integration → Ui React; Ui React → Runtime; Ui React → dialogue concepts.

### Amendment to D11.1

**Previous (v1 wording):** Framework does not ship production UI.

**Clarified:** The **Runtime subsystem** does not ship production UI. The **Presentation subsystem** provides reusable dialogue presentation implementations. Adoption of Presentation reference assets is optional (invariant 2); custom `IDialoguePresenter` implementations remain valid.

## Consequences

- Package layout documentation and structure tests include `presentation/` and (when present) `integration/`.
- Headless GUT tests continue to target `runtime/`, `compiler/`, and `data/` without Presentation or Integration.
- Presentation integration tests are separate from Runtime headless tests.
- ADR-010 presenter responsibilities (typewriter, tags, BBCode policy) apply to the **Presentation subsystem**, not to game demo code by default.
- Games using only Runtime bring any `IDialoguePresenter` (including minimal test doubles).
- Games may adopt Integration for starter / context / command wiring without forking Runtime (ADR-024).

## Localization amendment (ADR-020 D26.5, ADR-022 D28.19)

The Runtime/Presentation split is refined for localization by identity mechanism, without changing the subsystem boundaries above:

- **Runtime** owns translation resolution and localized delivery of authored dialogue **text** carrying a compiled translation identity (line body, choice labels), plus locale refresh and missing-translation fallback (ADR-022 D28.4, D28.8, D28.10, D28.19).
- **Presentation** resolves the **speaker display name** via `tr(speaker_id, "speakers")` — the single Presentation translation-resolution case (ADR-020 D26.16) — and otherwise displays Runtime-delivered localized text without catalog lookup or `CompiledDialogue` traversal.
- **Compiler** owns translation-identity generation, validation, and preservation (ADR-021); **Game / Godot project** owns translation catalogs and active locale selection.

This narrows the phrase "localization resolution" to compiled-identity authored text on Runtime; it does not weaken the core invariants (Runtime SHALL NOT import Presentation or Integration).

## Integration amendment (ADR-024)

Optional `integration/` provides editor-first game-boundary ergonomics (conversation starter, reference `GameContext`, command bridge) without weakening D1.1 game-authoritative state, D20.2 Runtime purity, or D26.5 / D28.7 catalog ownership. See [024-optional-game-integration-kit.md](024-optional-game-integration-kit.md).

## References

- [07-presentation-product-spec.md](../07-presentation-product-spec.md)
- [decisions/015-presentation-product-concepts.md](015-presentation-product-concepts.md)
- [00-project-goals.md](../00-project-goals.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/010-ui-and-presenter.md](010-ui-and-presenter.md)
- [decisions/001-philosophy-and-scope.md](001-philosophy-and-scope.md)
- [decisions/020-localization-architecture.md](020-localization-architecture.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
- [decisions/024-optional-game-integration-kit.md](024-optional-game-integration-kit.md)
