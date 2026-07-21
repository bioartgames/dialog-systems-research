# ADR 024: Optional Game Integration Kit

**Status:** Accepted  
**Date:** 2026-07-21  
**Decisions:** D30.1–D30.11  
**Extends:** ADR-001 (Philosophy), ADR-007 (Commands), ADR-009 (Game Integration), ADR-014 (Product Structure and Presentation), ADR-018 (Presentation Consumer Customization), ADR-019 (Presentation Growth Constraints), ADR-020 / ADR-022 (Localization ownership constraints)  
**Amends:** ADR-014 D20.1 / D20.6 (product structure diagram and game-boundary ergonomics clarification — without weakening Runtime purity or game-authoritative state)  
**Clarifying amendments completed in:** ADR-014, `06-product-structure.md`, `01-architecture-overview.md`, architecture `README.md`, `04-runtime-and-integration.md`, `addons/dialogue_framework/README.md`  
**Planning source:** [../planning/optional-game-integration-kit-adr-outline.md](../planning/optional-game-integration-kit-adr-outline.md)  
**Implementation:** Kit code under `integration/` is **authorized** by this Acceptance; schedule via DAG / implementation plan. D25.2 Runtime contracts (`IDialoguePresenter`, `ConversationStep`, phases, compiled schemas) remain **unauthorized** by this ADR.

---

## Context

ADR-014 established a two-subsystem product: **Runtime** (required, headless) and **Presentation** (optional, editor-first). ADR-018 made Presentation customization Inspector/scene-first. ADR-014 D20.6 still assigned game integration responsibilities to games: implement `GameContext`, register commands, orchestrate conversations, and wire a presenter.

The showcase (`game/dialogue_demo/scripts/`) shows that most integration glue is small and repetitive. Presentation already reduced script tax for dialogue UI; game boundary wiring did not. Leaving that gap undecided risks either silent Runtime expansion or permanent script-first adoption cost.

Board resolutions (planning §10, 2026-07-21) selected **Option A — Optional Integration kit**, package name `integration/`, no Presentation import, v1 surfaces listed below, Godot-native translation assets as the primary localization story.

---

## Problem Statement

The Dialogue Framework needs an explicit product decision:

> Does it ship optional, editor-first surfaces that configure the **game boundary**, and if so with what package invariants — without Runtime absorbing game save authority, game modes, or translation catalogs?

---

## Decision D30.1 — Primary Product Choice

### Decision

**Adopt Option A: Optional Integration kit.**

| Option | Verdict |
|--------|---------|
| **A — Optional Integration kit** | **Accepted** |
| **B — Expand Runtime** | **Rejected** — weakens headless/game-agnostic Runtime; risks D1.1 / D28.7 tension |
| **C — Docs-only** | **Rejected as the product answer** — does not meet editor-first integration goal; remains a valid interim until kit implementation lands |

### Rationale

Mirrors Presentation’s successful optional-adoption pattern (ADR-014 invariant 2, ADR-018): ship the common 80% as Resources/Nodes; keep scripts as override. Preserves D1.1, D20.2, D10.2–D10.3, and D26.5/D28.7.

---

## Decision D30.2 — Package Layout and Dependency Invariants

### Decision

`addons/dialogue_framework/` product structure **adds**:

- `integration/` — optional Game Integration kit

**Normative invariants** (SHALL NOT be weakened without a new ADR):

1. **Runtime SHALL NOT import Integration** (or Presentation).
2. **Integration MAY depend on Runtime and `data/` only.**
3. **Integration SHALL NOT import `presentation/`.** Presenters are wired by `NodePath` / `IDialoguePresenter` references supplied by the game scene.
4. **Integration SHALL remain optional to adopt.** Custom `GameContext`, manual `CommandRegistry` registration, and bespoke orchestrators remain valid.
5. Games may depend on Runtime, Presentation, and/or Integration independently.

### Normative dependency graph

```text
                Runtime
               ▲       ▲
               │       │
        Presentation   Integration
               ▲       ▲
               │       │
              Game (wires both as needed)
```

Ui React remains optional Presentation infrastructure only (ADR-014 D20.5). Integration must not depend on Ui React.

---

## Decision D30.3 — Optional Adoption Rule

### Decision

- Games **are not required** to use Integration.
- Headless Runtime tests **must not** require Integration (or Presentation) to pass.
- Adopting Integration must be sufficient to configure a minimal playable conversation start path via Inspector exports when combined with a wired presenter and compiled dialogue resource.
- Replacing any Integration reference type with a game subclass or alternate implementation must not require forking Runtime.

---

## Decision D30.4 — v1 Kit Surfaces (In Scope)

### Decision

**v1 Integration kit includes:**

| Surface | Architectural form | Notes |
|---------|-------------------|--------|
| **Conversation starter** | Node | `@export` compiled dialogue / path, entry title, presenter path, context; calls existing `ConversationController` APIs only |
| **Resource / dictionary-backed `GameContext`** | Reference implementation of ADR-009 D10.1 | Inspector-authored maps; **not** authoritative game save |
| **Command bridge** | Resource + registrar | Maps selected `@commands` to context methods; game-mode commands exposed as hooks/callables/signals |
| **CompiledDialogue load helper** | Thin utility | Optional; may live under `integration/` or `tools/` per implementation design |
| **Translation workflow guidance** | Docs (+ optional thin registrar) | **Primary:** Godot CSV / `.translation` + Project Settings |

Concrete property lists and scene trees are **implementation design**, not defined here.

---

## Decision D30.5 — Explicit Out of Scope / Non-Goals

### Decision

Integration **must not**:

- Own authoritative flags/items/quests/save data (ADR-001 D1.1).
- Own translation catalog content or locale selection policy (ADR-020 D26.5, ADR-022 D28.7).
- Ship shop UI, cutscene directors, camera/anim systems as framework game modes (ADR-009 D10.2–D10.3) — only **delegation hooks**.
- Import or own Presentation layouts/themes/policies.
- Require a visual dialogue editor (ADR-013 D19.1 remains deferred).
- Make custom JSON translation catalogs the primary framework story (showcase JSON may remain demo-local).
- Expand `IDialoguePresenter`, `ConversationStep`, or `ConversationPhase` unless a future ADR authorizes it.

Demo-only UI (`showcase_panel` and equivalent) remains outside the kit.

---

## Decision D30.6 — Override and Extension Model

### Decision

Editor-first defaults with script escape hatches:

1. **Resources / Nodes** are the default authoring surface (same spirit as ADR-018).
2. Games may **subclass** kit `GameContext` implementations or **replace** them entirely with a custom `GameContext`.
3. Games may ignore the command bridge and call `CommandRegistry.register` directly.
4. Games may ignore the starter Node and orchestrate `ConversationController` manually.
5. Unsupported customization must not require editing addon sources; prefer composition and exports over mandatory subclassing of sealed types.

---

## Decision D30.7 — Relationship to Presentation

### Decision

- Integration **wires** a presenter instance; it does **not** implement dialogue HUD.
- Integration **must not** import `presentation/`.
- Games may use Presentation reference presenters, custom `IDialoguePresenter`s, or test doubles interchangeably with the starter.

---

## Decision D30.8 — Relationship to Localization

### Decision

1. Catalog authoring and locale policy remain **game / Godot project** responsibilities (D26.5 / D28.7).
2. **Primary adoption story:** Godot-native translation assets and Project Settings locales.
3. Integration may document and optionally provide a **thin registrar** that registers already-authored Godot `Translation` resources — it must not become Runtime catalog ownership.
4. Showcase-specific JSON catalogs are not elevated to the primary product contract by this ADR.

---

## Decision D30.9 — ADR-019 D25.2 Change Gate

### Decision

**Acceptance of this ADR authorizes** the optional Integration kit product decision and implementation of the D30.4 kit surfaces that do not change D25.2-gated Runtime contracts.

| Contract / structure | Authorized by this ADR? |
|----------------------|-------------------------|
| New `integration/` package + ADR-014 structure amendment | **Yes** |
| Reference `GameContext` in `integration/` (abstract unchanged) | **Yes** (kit surface); abstract API unchanged |
| Conversation starter Node using existing controller APIs | **Yes** (kit surface); no controller API change authorized here |
| Command bridge using existing `CommandRegistry` | **Yes** (kit surface); registry contract unchanged |
| Docs for Godot-native translation workflow | **Yes** |
| Changes to `IDialoguePresenter` / `ConversationStep` / phases / `CompiledLine` | **Not authorized** |
| Runtime importing Integration | **Forbidden** |

Routine Resource field naming inside the kit does not require a new ADR unless it changes product structure or Runtime contracts.

---

## Decision D30.10 — Architectural Verification Expectations

### Decision

When implemented:

| Property | Expectation |
|----------|-------------|
| Runtime GUT headless suite | Passes without loading Integration or Presentation |
| Optional adoption | Sample scene can start dialogue via Inspector-configured starter + wired presenter + compiled resource |
| Replaceability | Custom `GameContext` works with starter without Runtime fork |
| Catalog independence | Games can localize without Integration (D28.7) |
| Dependency purity | Static/boundary tests: Runtime has no `integration/` or `presentation/` references |

---

## Decision D30.11 — Showcase Fate

### Decision

Upon implementation planning:

- Showcase **may migrate** onto Integration surfaces for start/context/command wiring.
- Showcase **demo panel / smoke harness** remain game/demo-owned.
- Showcase may keep demo-local translation JSON until migrated to the Godot-native primary story; migration is not required for this ADR’s Acceptance.

Dual-path (kit + legacy showcase scripts) is allowed during transition.

---

## Alternatives Considered

| Alternative | Why rejected |
|-------------|--------------|
| Expand Runtime with defaults | Violates Runtime purity and game-authority clarity |
| Docs-only as final product answer | Fails editor-first integration goal |
| Integration imports Presentation | Couples optional packages; starter can wire by interface/path |
| JSON catalogs as primary kit story | Duplicates Godot translation pipeline; weakens D28.7 clarity |
| Kit owns save/flags | Contradicts D1.1 |

---

## Consequences

1. ADR-014 D20.1 / D20.6 and product structure docs include optional `integration/`.
2. Games may use Integration kit surfaces or continue full custom wiring.
3. Architecture and addon README document the Integration adoption path.
4. Kit implementation and DAG milestones may proceed under D30.4 / D30.9.
5. No D25.2 Runtime contract changes are authorized by this ADR.

---

## Architecture review (2026-07-21)

**Verdict: Accept.**

| Check | Result |
|-------|--------|
| D1.1 game-authoritative state | Preserved — kit reference context is not save authority (D30.5) |
| D20.2 Runtime purity | Preserved — Runtime must not import Integration (D30.2) |
| D10.2–D10.3 game modes | Preserved — hooks only, no framework shops/cutscenes (D30.5) |
| D26.5 / D28.7 catalog ownership | Preserved — Godot-native primary story; no Runtime catalogs (D30.8) |
| ADR-018 editor-first pattern | Consistent — Resources/Nodes with script escape hatches (D30.6) |
| D25.2 gate | Honored — no presenter/step/phase/schema expansion (D30.9) |
| Optional adoption | Explicit — headless Runtime tests must not require kit (D30.3) |
| Presentation coupling | Avoided — no `presentation/` import (D30.2, D30.7) |

No blocking conflicts with ADRs 001–023. No amendments required beyond the declared ADR-014 / product-structure sync.

---

## Related Documents

- [014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
- [009-game-integration.md](009-game-integration.md)
- [018-presentation-consumer-customization.md](018-presentation-consumer-customization.md)
- [019-presentation-growth-constraints.md](019-presentation-growth-constraints.md)
- [020-localization-architecture.md](020-localization-architecture.md)
- [022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
- [../planning/optional-game-integration-kit-adr-outline.md](../planning/optional-game-integration-kit-adr-outline.md)
