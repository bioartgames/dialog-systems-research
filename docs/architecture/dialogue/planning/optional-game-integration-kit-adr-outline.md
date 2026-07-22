# Planning Document: Optional Game Integration Kit ADR

**Status:** Planning artifact — not an ADR  
**Date:** 2026-07-21  
**Authority:** ADR-001 (philosophy), ADR-007/009 (commands / game integration), ADR-014 (product structure), ADR-018 (editor-first Presentation customization), ADR-019 D25.2 (change gate), ADR-020/022 (localization ownership)  
**Purpose:** Define scope, alternatives, and decision structure for an ADR that chooses how (if at all) the Dialogue Framework ships editor-first game-integration surfaces beyond Runtime contracts and Presentation UI  
**Audience:** Architecture Review Board  
**Proposed ADR number (working):** ADR-024  

---

## Executive Summary

Presentation is already an **optional, editor-first** subsystem (ADR-014, ADR-018): games wire a presenter; designers customize Layout / Theme / Policy / Input without subclassing Runtime.

Game integration remains **script-first** by design (ADR-014 D20.6, ADR-009 D10.1): games implement `GameContext`, register `CommandRegistry` handlers, orchestrate `ConversationController.start()` / `resume()`, and register translation catalogs (ADR-020 D26.5, ADR-022 D28.7).

The showcase under `game/dialogue_demo/scripts/` demonstrates that most of that glue is **small, repetitive, and game-shaped** — not Runtime logic. That creates a product gap: integrating dialogue with the game still feels developer-script-first, while dialogue *presentation* feels designer/editor-first.

This planning document proposes **one ADR** that must choose among:

| Option | Working name | Summary |
|--------|--------------|---------|
| **A** | **Optional Integration kit** | Ship an optional `integration/` (or equivalent) layer: Inspector-authored Resources + Nodes that configure the game boundary; scripts remain the override path. **Recommended.** |
| **B** | **Expand Runtime** | Absorb default context, command wiring, starters, and/or catalog registration into `runtime/`. |
| **C** | **Docs-only** | Keep product structure unchanged; improve guides and showcase as the reference pattern. |

The ADR must **not** weaken D1.1 (game-authoritative state), D20.1–D20.2 (Runtime headless / no Presentation import), or D26.5 / D28.7 (catalog and locale ownership remain game / Godot project).

---

## Problem Statement

Without an explicit decision, implementers and future agents will invent ad hoc answers to:

1. Whether dictionary-backed `GameContext`, command bridges, conversation-starter Nodes, and translation registrars are **framework product** or **demo-only**.
2. Where such code lives (`runtime/` vs `presentation/` vs new package vs `docs` / showcase only).
3. Whether editor-first game integration is in scope for the Dialogue Framework product or permanently deferred to games.
4. How optional adoption interacts with ADR-014’s two-subsystem model (does a third subsystem appear?).
5. Which surfaces are high-ROI enough to authorize under ADR-019 D25.2 vs YAGNI.

The showcase already implements several candidates (`ShowcaseGameContext`, `ShowcaseCommandHandlers`, `ShowcaseDialogueLoader`, `ShowcaseTranslationCatalog`, orchestrator wiring). Leaving them demo-only without a product decision risks either **silent promotion into Runtime** (architecture drift) or **permanent script tax** on every adopter.

---

## Dependency Graph

```text
ADR-001 Philosophy (D1.1 game-authoritative state)
ADR-009 Game integration (D10.1 GameContext contract)
ADR-014 Product structure (Runtime / Presentation; D20.6 game boundary)
ADR-018 Editor-first Presentation customization
ADR-019 D25.2 change gate
ADR-020 / ADR-022 Localization ownership (catalogs = game)
        |
        v
ADR-024 (proposed) — Optional Game Integration Kit
        |
        |  chooses Option A / B / C
        |  defines package boundary, optional-adoption invariant,
        |  editor-first surfaces in/out of scope, override rules,
        |  D25.2 implications, verification expectations
        |
        v
Future implementation (prohibited for gated surfaces until ADR Accepted
and D25.2 implications explicitly authorized)
```

---

## Alternatives (to be decided by the ADR)

### Option A — Optional Integration kit (recommended default for the ADR draft)

**Decision shape:** Add a third **optional** product package (working name `integration/`) that may depend on Runtime (and optionally Presentation types for wiring helpers) but that **Runtime must not import**.

**Ships (candidate surfaces — ADR must accept/reject each):**

| Surface | Editor-first form | Script override |
|---------|-------------------|-----------------|
| Conversation starter | Node with `@export` compiled dialogue, entry, presenter path, context | Custom orchestrator still valid |
| Dictionary / Resource-backed `GameContext` | Resource maps for flags/items/quests/display values | Subclass or replace with save-backed context |
| Command bridge | Resource listing context-method commands + hooks for game-mode commands | Manual `CommandRegistry.register` |
| Translation workflow helper | Docs + optional registrar aligned with Godot CSV/`.translation` (not Runtime-owned catalogs) | Game registers catalogs any way it chooses |
| Load / import helpers | Thin tools API | Direct `ResourceLoader` |

**Invariants to preserve:**

1. Integration is **optional to adopt** (same spirit as Presentation invariant 2).
2. **Runtime SHALL NOT import Integration** (extend Runtime purity).
3. Integration **SHALL NOT** claim authoritative game save ownership (D1.1).
4. Integration **SHALL NOT** own translation catalogs or locale policy (D26.5 / D28.7).
5. Game-mode commands (`@open_shop`, `@cutscene`, camera/anim) remain **delegated** to game hooks (D10.2–D10.3).

**Rationale (recommendation):** Highest ROI for “designer/editor-first integration” without reversing game-authority philosophy. Mirrors Presentation’s successful optional-adoption pattern.

**Risks:** Product complexity (third package); temptation to grow Integration into a mini-game-framework; docs must keep “optional / overridable” sharp.

---

### Option B — Expand Runtime

**Decision shape:** Default context, starters, and/or command auto-registration live under `runtime/` (or always-on autoloads).

**Why reject (unless ADR finds overriding evidence):**

- Weakens Runtime as a headless, game-agnostic interpreter (D1.2, D1.6, D20.2).
- Risks implying dialogue owns flags/items/quests (tension with D1.1).
- Catalog registration in Runtime contradicts D28.7.
- Harder to keep “optional” — Runtime becomes the forced integration model.

**When it might still be argued:** Only for *pure* conveniences with zero game policy (e.g. a static helper to load `CompiledDialogue`) — those can also live in Integration or `tools/` without expanding Runtime’s role.

---

### Option C — Docs-only

**Decision shape:** No new package. Improve `addons/dialogue_framework/docs/` and keep showcase as the reference implementation.

**Pros:** YAGNI; zero D25.2 surface; no product-structure ADR risk.  
**Cons:** Does not reduce script-first integration cost; every game still copies showcase glue; does not answer the editor-first product goal.

**Use when:** Board decides editor-first game integration is out of product scope for the current horizon.

---

## Proposed ADR-024 Outline

### 1. Header (required)

- Title: Optional Game Integration Kit (or Docs-Only Deferral)
- Status: Proposed → Accepted
- Decisions: D30.1–D30.n (number after acceptance)
- Extends / Amends: ADR-014 D20.1 / D20.6 (product structure / game boundary clarification); possibly ADR-009 (integration ergonomics without changing `GameContext` abstract contract)
- Prerequisite: None beyond accepted ADR-001–023 for localization; this ADR is orthogonal to localization contracts but must cite D26.5 / D28.7 as constraints

### 2. Context

- Restate D20.6 game responsibilities vs Presentation optional adoption.
- Cite showcase scripts as evidence of repeated glue.
- State the product goal: editor-first configuration of the **game boundary**, not absorption of game systems.

### 3. Core question

> **Does the Dialogue Framework ship optional, editor-first game-integration surfaces; if so, as what package with what invariants; if not, is the answer docs-only or Runtime expansion?**

### 4. Normative decision block (ADR must pick exactly one primary option)

| ID | Topic |
|----|--------|
| D30.1 | Primary product decision: Option A / B / C |
| D30.2 | Package / folder layout and dependency invariants (if A or B) |
| D30.3 | Optional-adoption rule (who must / must not use it) |
| D30.4 | In-scope editor-first surfaces (accepted list) |
| D30.5 | Explicit out-of-scope / non-goals (orchestrator demo UI, save authority, catalogs, shop/cutscene directors) |
| D30.6 | Override / extension model (Resource + Node defaults; script subclass or replace) |
| D30.7 | Relationship to Presentation (may Integration wire presenters? must it avoid owning HUD?) |
| D30.8 | Relationship to localization (helpers vs ownership; prefer Godot-native translation assets) |
| D30.9 | ADR-019 D25.2 implications (what is gated; what is not) |
| D30.10 | Verification expectations (optional kit does not break headless Runtime tests; adoption remains optional) |
| D30.11 | Migration / showcase fate (demo keeps custom scripts vs migrates to kit) |

### 5. Scope — must define

If Option A (recommended):

- Exact package name and import rules (`integration/` ↔ `runtime/`, `presentation/`, game).
- Which of the five candidate surfaces are **in v1 of the kit**.
- Inspector/Resource contracts at architectural level (not full API dump).
- That `GameContext` abstract remains the contract; kit provides a **reference implementation**, not a replacement philosophy.
- That `CommandManifest` / compile validation remain authoritative for unknown `@commands`.

If Option C:

- Explicit deferral statement and what docs/showcase must cover instead.
- Criteria for revisiting (e.g. adopter feedback threshold).

If Option B:

- Precise list of Runtime additions and proof they do not violate D1.1 / D20.2 / D28.7 — expected to be empty or extremely narrow.

### 6. Explicit non-scope (recommended text for the ADR)

The ADR must **not**:

- Move authoritative save/flags/items/quests into Dialogue Framework ownership (D1.1).
- Make Runtime depend on Presentation or Integration.
- Own translation catalog content or locale selection policy (D26.5 / D28.7).
- Ship game-mode systems (shop UI, cutscene director, camera rigs) as Runtime features (D10.2–D10.3).
- Require games to adopt the kit (if Option A).
- Redesign Presentation Layout/Theme/Policy (already ADR-015–018).
- Mandate a visual dialogue editor (D19.1 deferred).

### 7. D25.2 change-gate analysis (ADR must complete)

| Surface | Likely gated? | Notes |
|---------|---------------|-------|
| New `integration/` package + dependency graph | **Yes** (product structure / ADR-014 amendment) | Treat as structural decision |
| Reference `GameContext` implementation | **No** to abstract contract; **Yes** if Runtime API changes | Prefer kit-local class |
| Conversation starter Node | **No** if it only calls existing `ConversationController` APIs | Yes if new controller API required |
| Command bridge Resource | **No** if it only uses `CommandRegistry` | Yes if registry contract changes |
| Translation helper | **No** if game-side only | **Forbidden** in Runtime as catalog owner |
| `IDialoguePresenter` / `ConversationStep` / phases | **Out of scope** unless starter forces contract change | Avoid |

### 8. Verification expectations (architectural)

- Headless Runtime GUT suite remains runnable without Integration or Presentation.
- Adopting Integration is sufficient to start a conversation from Inspector-configured exports in a sample scene (if Option A).
- Replacing kit `GameContext` with a custom subclass does not require forking Runtime.
- Catalog registration remains possible without Integration (D28.7).

### 9. Consequences checklist (ADR must fill)

- ADR-014 amendment (product structure diagram).
- Developer Guide / README integration section.
- Showcase: migrate, dual-path, or leave as advanced sample.
- DAG / implementation milestones (only after Accepted).

### 10. Open questions for the Board — **RESOLVED 2026-07-21**

| # | Question | Board resolution |
|---|----------|------------------|
| 1 | Package name | **`integration/`** under `addons/dialogue_framework/` |
| 2 | May Integration depend on Presentation? | **No.** Integration may depend on Runtime/data only. Starter wires presenters via `NodePath` / `IDialoguePresenter` without importing `presentation/`. |
| 3 | Resource-backed context in v1 kit? | **Yes.** v1 kit includes Resource/dictionary-backed `GameContext` reference implementation alongside the starter Node and command bridge. |
| 4 | JSON catalog helper vs Godot CSV | **Primary story: Godot-native translation assets** (CSV / `.translation` + Project Settings). Optional thin registrar helper allowed; custom JSON loader is **not** the primary framework story (showcase JSON may remain demo-local). |
| 5 | Kit-internal ADR series? | **ADR-024 is sufficient for v1 kit scope.** Further kit growth that changes product structure or Runtime contracts needs a new ADR; routine Resource field design does not. |

**Primary option selected:** **A — Optional Integration kit** (B and C rejected for the product answer; C remains a valid interim until ADR-024 is Accepted and implemented).

---

## Recommended Board posture (superseded by §10 resolutions)

Historical planning advice; normative resolutions are in §10 and ADR-024.

---

## Relationship to Existing Showcase Scripts

| Showcase script | Maps to candidate surface | Fate under Option A (illustrative) |
|-----------------|---------------------------|------------------------------------|
| `showcase_game_context.gd` | Resource/dictionary `GameContext` | Become kit reference impl or thin wrapper |
| `showcase_command_handlers.gd` | Command bridge Resource | Become kit registrar driven by Resource |
| `showcase_dialogue_loader.gd` | Load helper | Kit or `tools/` helper |
| `showcase_translation_catalog.gd` | Translation helper | Docs + optional helper; prefer Godot-native assets |
| `showcase_orchestrator.gd` | Starter + demo harness | Starter Node absorbs start/resume wiring; demo panel stays game/demo |
| `showcase_panel.gd` | Demo UI | Remains showcase-only |

---

## Success Criteria for the Eventual ADR

The ADR is ready for acceptance when it:

1. Selects exactly one primary option (A / B / C) with rationale and rejected alternatives.
2. States dependency invariants that cannot be weakened without a new ADR.
3. Lists in-scope and out-of-scope surfaces without ambiguity.
4. Completes D25.2 gating table.
5. Does not contradict D1.1, D20.2, D10.2–D10.3, or D28.7.
6. Defines optional adoption clearly enough that Runtime tests need not load the kit.

---

## Explicit Non-Goals of This Planning Document

- This document is **not** an Accepted ADR and does **not** authorize implementation.
- It does not specify GDScript APIs, Resource property lists, or scene trees.
- It does not schedule DAG milestones.
- It does not migrate the showcase.

---

## Related Documents

- [decisions/001-philosophy-and-scope.md](../decisions/001-philosophy-and-scope.md) — D1.1, D1.6  
- [decisions/009-game-integration.md](../decisions/009-game-integration.md) — D10.1–D10.6  
- [decisions/014-product-structure-and-presentation.md](../decisions/014-product-structure-and-presentation.md) — D20.1–D20.6  
- [decisions/018-presentation-consumer-customization.md](../decisions/018-presentation-consumer-customization.md) — editor-first Presentation  
- [decisions/019-presentation-growth-constraints.md](../decisions/019-presentation-growth-constraints.md) — D25.2  
- [decisions/020-localization-architecture.md](../decisions/020-localization-architecture.md) — D26.5  
- [decisions/022-localized-runtime-delivery-locale-switching.md](../decisions/022-localized-runtime-delivery-locale-switching.md) — D28.7  
- [localization-contract-adrs-outline.md](localization-contract-adrs-outline.md) — prior planning-outline precedent  

---

## Next Step After Board Review

1. ~~Resolve Open Questions (§10).~~ **Done 2026-07-21.**  
2. ~~Author **ADR-024** from this outline with Status **Proposed**.~~ **Done.**  
3. ~~Architecture review → **Accepted**.~~ **Done 2026-07-21.**  
4. ~~Implementation plan / DAG entries for authorized kit surfaces (D30.4).~~ **Done** — see [adr-024-integration-kit-implementation-plan.md](adr-024-integration-kit-implementation-plan.md) and [../../../dag.md](../../../dag.md); Linear epic [CRG-345](https://linear.app/lock-and-key/issue/CRG-345/epic-optional-game-integration-kit-adr-024).  
5. ~~Implement IK-0…IK-6.~~ **Done** (surfaces, suite, adoption docs).
6. ~~IK-7 showcase dual-path migrate.~~ **Done** ([CRG-352](https://linear.app/lock-and-key/issue/CRG-352/ik-7-showcase-dual-path-migrate-onto-integration-kit)).
