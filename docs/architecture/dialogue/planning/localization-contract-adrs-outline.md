# Planning Document: Localization Contract ADRs

**Status:** Planning artifact — not an ADR  
**Date:** 2026-07-11  
**Authority:** ADR-001 through ADR-020 (accepted); ADR-019 D25.2 (change gate)  
**Purpose:** Define scope and structure for the two ADRs required before localization implementation may begin  
**Audience:** Architecture Review Board  

---

## Executive Summary

ADR-020 establishes the Localization subsystem philosophy, coverage model, ownership principles, lifecycle, extension model, and deferred questions. It intentionally does **not** define the contracts that make choice-label localization and extended locale-switch behavior implementable.

The Architecture Board has determined that **two additional ADRs** are required before implementation:

| Proposed ADR | Working title | Sequence |
|--------------|---------------|----------|
| **ADR A** | Localized Authoring and Compiled Identity Contract | **First** |
| **ADR B** | Localized Runtime Delivery and Locale Switching Contract | **Second** (depends on ADR A) |

Implementation of any ADR-019 D25.2-gated contract remains **prohibited** until the relevant proposed ADR is accepted.

---

## Dependency Graph

```text
ADR-020 Localization Architecture (accepted)
  |
  |  philosophy, coverage, ownership principles,
  |  deferred questions (D26.17, D26.18),
  |  gated-work enumeration (not designed)
  |
  v
ADR A — Localized Authoring and Compiled Identity Contract
  |
  |  language-neutral identity contract
  |  authoring / compiler / compiled-data responsibilities
  |  compatibility and compile-time verification expectations
  |
  v
ADR B — Localized Runtime Delivery and Locale Switching Contract
  |
  |  runtime delivery contract
  |  ConversationStep localization semantics
  |  locale-switch contract by phase
  |  presentation assumptions, save/resume, catalog boundary
  |
  v
Future implementation (still prohibited until both ADRs accepted
and ADR-019 D25.2 implications explicitly resolved per ADR)
```

---

# ADR A — Localized Authoring and Compiled Identity Contract

## 1. Purpose

Define the architectural contract for how localized authored **text** (per ADR-020 D26.4) is identified in authoring, preserved through compilation, and represented in language-neutral compiled dialogue data—so that Runtime can resolve localized strings without parsing `.dlg` source in production.

ADR A answers: **What translation identity must exist before runtime, and who is responsible for creating, validating, and preserving it?**

## 2. Problem Statement

ADR-020 classifies choice labels as **Localized** with Runtime-owned translation resolution (D26.4, D26.5) and states that every localized authored **text** object has a stable translation identity (D26.6). The accepted data model (ADR-003 D3.8) carries `translation_key` only on `LINE` compiled nodes. The authoring format documents `[id:]` only on dialogue lines (02-authoring-format). The compilation pipeline (ADR-005) does not define identity generation for choice labels.

Without ADR A, implementers would be forced to invent:

- how choice-label identity is expressed in authoring,
- what the compiler must guarantee about identity,
- what compiled data must preserve,
- how compiled resources without required identity are handled.

ADR-020 explicitly deferred these mechanics to future ADRs governed by ADR-019 D25.2.

## 3. Scope

ADR A should define architectural contracts for:

- Translation identity for localized authored **text** surfaces (line body, choice labels, and future text surfaces per D26.4).
- Relationship between existing LINE identity (ADR-011 D13.2) and any extension to additional surfaces.
- Authoring-format responsibilities for expressing or omitting author-provided identity.
- Compiler responsibilities for identity generation, validation, and failure policy.
- Compiled-data responsibilities for preserving identity and source text for debug/fallback.
- Identity stability, uniqueness, and language-neutrality guarantees (principles from D26.6).
- Compatibility and versioning expectations when compiled resources lack required localization identity (principles from D26.12).
- Compile-time verification expectations attributable to ADR-012.
- Explicit statement of what ADR A does **not** decide (runtime resolution, locale switching, presentation).

Speaker display names (D26.16) use `speaker_id` as identity and are resolved in Presentation; ADR A should state whether and how speaker identity intersects with compiled identity (without designing speaker schema changes).

## 4. Explicit Non-Scope

ADR A must **not** define:

- Runtime translation lookup or delivery semantics.
- `ConversationStep` localized text delivery.
- Locale switching or phase behavior.
- Presentation display or speaker `tr()` behavior.
- Save/resume localization behavior.
- Translation catalog registration or `TranslationServer` integration.
- Whether choice labels may contain interpolation (ADR-020 D26.17 — deferred; may be addressed in ADR A only if the board scopes it here, otherwise remains for ADR B or a later ADR).
- Portrait, screen-reader, or custom line type localization (deferred per ADR-020).
- Concrete `.dlg` syntax, schema field names, serialization layout, compiler passes, or algorithms.
- Migration or reimport implementation.

## 5. Existing ADRs That Provide Inputs

| ADR / Document | Relevant input |
|----------------|----------------|
| **ADR-020** | Coverage model (D26.4), identity principles (D26.6), ownership (D26.5), pipeline stages through compiled data (D26.7), compatibility principles (D26.12), gated-work enumeration, deferred D26.17 |
| **ADR-003** | `CompiledLine` kinds, `translation_key` on LINE, `[id:]` / line ID model (D3.7, D3.8) |
| **ADR-004** | `Speaker:` lines, choice syntax, `[id:]` on dialogue lines only (D4.3, D4.4) |
| **ADR-005** | Compile-at-import pipeline, choice grouping (D5.8), version fields (D5.2) |
| **ADR-011** | D13.2 LINE identity rules (existing, to be extended in scope only) |
| **ADR-012** | Strict compile, golden snapshots (D15.1, D16.4), extension points (D17.3) |
| **ADR-019** | D25.2 change gate for `CompiledLine` / `CompiledDialogue` |
| **02-authoring-format.md** | Authoring syntax for lines, choices, stable line IDs |
| **03-compilation-and-data.md** | Schema tables, `format_version`, `compiler_version` |

## 6. Existing ADRs That Will Eventually Require Amendment

| ADR / Document | Why amendment will be needed |
|----------------|------------------------------|
| **ADR-003** | Data model must reflect accepted identity contract for all localized text surfaces |
| **ADR-004** | Authoring format must reflect accepted identity expression rules |
| **ADR-005** | Compilation pipeline must reflect accepted compiler identity responsibilities |
| **ADR-012** | Testing and validation expectations for identity contract |
| **ADR-020** | Cross-reference from subsystem ADR to contract ADR (clarification, not reversal) |
| **02-authoring-format.md** | Authoring rules for localized surfaces |
| **03-compilation-and-data.md** | Compiled schema documentation |
| **05-open-questions.md** | Record resolved/deferred identity questions |

ADR B and runtime/presentation ADRs are **not** amended by ADR A alone.

## 7. Architectural Questions That MUST Be Answered

*Listed for ADR A authorship. This planning document does not answer them.*

1. For each localized authored **text** surface (LINE body, choice label), what translation identity must exist in compiled data before runtime?
2. Is author-provided identity required, optional, or forbidden for each localized text surface?
3. What is the relationship between existing LINE `translation_key` / `[id:]` rules (D13.2) and choice-label identity—same mechanism, parallel mechanism, or unified model with surface-specific rules?
4. What uniqueness scope applies to translation identities (per file, per project, global)?
5. What compiler guarantees apply when author-provided identity is missing (deterministic fallback per D26.6)?
6. What compiler guarantees apply when author-provided identity conflicts (duplicate, invalid shape)?
7. What compile-time failure policy applies to identity validation errors (fail import vs warn)?
8. What must compiled data preserve besides identity (e.g., source text for debug/fallback per D26.7 pipeline table)?
9. What compatibility rule applies when a compiled resource lacks identity required by the accepted contract?
10. What verification expectations apply at the authoring/compiler/data layer (per D26.14, scoped to identity)?
11. Does speaker `speaker_id` require any compiled identity beyond what ADR-020 D26.16 already defines?

## 8. Architectural Questions That MUST NOT Be Answered

ADR A must **not** answer (defer to ADR B or implementation):

1. How Runtime performs translation lookup.
2. What string Runtime delivers on `ConversationStep` for LINE or CHOICES.
3. Behavior when a translation catalog entry is missing.
4. Locale-switch or phase behavior.
5. Whether locale refresh re-runs interpolation (D26.18).
6. Whether choice labels may contain `{brace}` interpolation (D26.17), unless the board explicitly scopes D26.17 into ADR A.
7. Concrete field names, serialized keys, or storage layout for identity in compiled data.
8. Parser or compiler algorithm steps.
9. `format_version` / `compiler_version` numeric values or migration procedures.
10. Godot `TranslationServer` API usage.
11. Presenter contract changes.

## 9. Proposed Decision Sections

*Section headings only. No decisions are recorded here.*

| Section | Topic |
|---------|--------|
| A.1 | Context and relationship to ADR-020 |
| A.2 | Localized text surfaces in scope of this contract |
| A.3 | Translation identity contract (author-provided vs generated) |
| A.4 | Identity stability, uniqueness, and language-neutrality guarantees |
| A.5 | Authoring-format responsibilities |
| A.6 | Compiler identity generation and validation responsibilities |
| A.7 | Compiled-data preservation responsibilities |
| A.8 | Speaker identity boundary (D26.16 interaction) |
| A.9 | Compatibility and versioning contract |
| A.10 | Compile-time verification expectations |
| A.11 | Relationship to optional compile processor (ADR-012 D17.3) |
| A.12 | Consequences and required document amendments |
| A.13 | ADR-019 D25.2 gate statement |

## 10. Expected Invariants

*Invariants ADR A is expected to establish or restate. Not decided here.*

- Compiled dialogue resources remain language-neutral artifacts.
- Localized authored text has translation identity before runtime resolution.
- Translation identity belongs to authored content, not display layout (D26.6).
- Runtime does not parse `.dlg` source in production (ADR-003 consequence).
- Existing LINE identities per D13.2 remain valid unless ADR A explicitly defines a superseding rule with compatibility guarantees.
- Identity is not persisted as localized display text in save data (consistent with D26.11; stated in ADR A only as cross-layer invariant reference).

## 11. Expected Ownership Boundaries

| Responsibility | Expected owner after ADR A |
|----------------|--------------------------|
| Expressing author-provided identity | Authoring format |
| Generating fallback identity | Compiler |
| Validating identity shape and uniqueness | Compiler |
| Preserving identity in compiled data | Data schema (as contract, not layout) |
| Translation catalog content | Game / Godot project (out of ADR A scope) |
| Runtime identity resolution | ADR B (out of ADR A scope) |
| Speaker display name resolution | Presentation per D26.16 (out of ADR A scope) |

## 12. Expected Consequences

- ADR-003, ADR-004, ADR-005, and architecture docs `02` and `03` will require amendment to reflect accepted contract.
- ADR-012 verification expectations will expand for compiler/data identity properties.
- Implementation of choice-label identity in compiled data becomes **architecturally authorized** but remains **implementation-blocked** until ADR B accepts runtime delivery contract.
- Golden compile snapshot expectations (D16.4) will eventually change when identity contract is implemented; ADR A should state the architectural expectation, not the snapshot contents.
- `05-open-questions.md` may record closure or continued deferral of identity-related questions.

## 13. ADR-019 D25.2 Implications

ADR A is expected to **trigger D25.2** if accepted decisions change:

- `CompiledLine` schema (choice-label identity; possible unification with LINE `translation_key` model).
- `CompiledDialogue` schema / `format_version` semantics for localization identity evolution.

ADR A must:

- Explicitly state which gated contracts it changes.
- Explicitly state that **implementation** of those changes remains prohibited until ADR A is **Accepted**.
- Not design the schema change—only authorize the architectural contract implementation must satisfy.

ADR A is **not** expected to trigger D25.2 for:

- `ConversationStep` (ADR B).
- `ConversationPhase` (ADR B).
- `IDialoguePresenter` (ADR B, unless presenter contract unexpectedly required—which ADR-020 D26.16 indicates is not required for speakers).

## 14. Dependencies on ADR B

| Dependency | Direction |
|------------|-----------|
| ADR B **depends on** ADR A | Runtime delivery contract requires knowing what identity compiled data guarantees. |
| ADR A **does not depend on** ADR B | Identity contract can be accepted independently of runtime delivery semantics. |
| ADR A must not assume ADR B outcomes | e.g., must not presuppose missing-translation runtime policy or locale-refresh interpolation behavior. |

**Acceptance gate:** ADR A acceptance is **required** before any implementation touching `CompiledLine` / `CompiledDialogue` localization identity. ADR A acceptance alone does **not** authorize end-to-end choice localization (requires ADR B).

---

# ADR B — Localized Runtime Delivery and Locale Switching Contract

## 1. Purpose

Define the architectural contract for how localized authored **text** (with identity established by ADR A) is resolved at runtime, delivered through `ConversationStep`, refreshed on locale change across conversation phases, and consumed by Presentation—while preserving language-neutral traversal, save/resume coordinates, and ADR-020 ownership boundaries (including speaker resolution in Presentation per D26.16).

ADR B answers: **What does Runtime guarantee when delivering localized text, what may Presentation assume, and what happens during locale switching and save/resume?**

## 2. Problem Statement

ADR-020 establishes that:

- Choice labels are **Localized** with Runtime-owned translation resolution (new commitment, not yet implemented).
- `AwaitingChoice` locale refresh is a **new guarantee** (D26.10), ADR-019 D25.2-gated.
- LINE locale refresh for `PresentingLine` / `AwaitingInput` is **existing** (D13.4).
- Speaker names remain Presentation-resolved (D26.16).
- Save/resume is language-neutral (D26.11).
- Interpolation values are **Delegated** to game; placement vs value ownership is defined (D26.8-interpolation).
- D26.17 (choice interpolation) and D26.18 (locale refresh re-running interpolation) are **deferred**.

Without ADR B, implementers would be forced to invent:

- `ConversationStep` localized delivery semantics for choice labels.
- Missing-translation behavior.
- Locale-switch contract details beyond ADR-020's phase table.
- Whether locale refresh re-fetches interpolation values.
- Translation catalog integration boundary at runtime.
- Presentation assumptions for localized vs speaker-resolved text.

ADR-020's gated-work section identifies affected contracts but does not design them.

## 3. Scope

ADR B should define architectural contracts for:

- Runtime localization resolution for compiled-identity authored text (line body, choice labels).
- `ConversationStep` delivery semantics for localized text (contract level, not layout).
- Missing-translation behavior contract (fallback, source text, error, warning—decision required, not designed here).
- Locale-switch behavior for every `ConversationPhase` per D26.10, including `AwaitingChoice` extension beyond D13.4.
- Locale behavior during `WAIT` steps and interaction with surrounding phases (reference ADR-020 note on D6.5).
- Presentation assumptions and prohibitions (extending D26.9, retaining D26.16 speaker case).
- Save/resume localization guarantees (extending D26.11 as runtime contract).
- Translation catalog / locale selection boundary (game and Godot project ownership per D26.5).
- Resolution of or explicit continued deferral of D26.17 and D26.18.
- Runtime and presentation verification expectations (per D26.14, scoped to delivery and locale-switch).

## 4. Explicit Non-Scope

ADR B must **not** define:

- Authoring syntax for translation identity (ADR A).
- Compiler identity generation or validation (ADR A).
- Compiled schema layout or serialization (ADR A).
- Concrete DTO member names or step structure.
- Concrete `TranslationServer` API calls or catalog file formats.
- Translation authoring tools, machine translation, or translation management (ADR-020 non-goals D26.15).
- Game UI outside dialogue conversations.
- Game mode UI from commands.
- Portrait, screen-reader, or narration localization (deferred).
- Presentation typewriter, theme, policy, or input mechanics except as they consume localized strings.
- Migration or reimport implementation.
- Algorithms for step building, phase transitions, or translation lookup.

## 5. Existing ADRs That Provide Inputs

| ADR / Document | Relevant input |
|----------------|----------------|
| **ADR-020** | Coverage (D26.4), ownership (D26.5, D26.16), runtime guarantees (D26.8), presentation guarantees (D26.9), locale switching (D26.10), save/resume (D26.11), interpolation delegation (D26.8-interpolation), deferred D26.17/D26.18, gated-work list |
| **ADR A** (future) | Compiled identity contract—prerequisite input |
| **ADR-002** | Conversation phases (D2.3), hybrid async delivery (D2.5) |
| **ADR-006** | CHOICES flow (D6.9), execution model, WAIT (D6.5) |
| **ADR-010** | `IDialoguePresenter` contract (D11.2), speaker `tr()` (D11.4), BBCode display (D11.6) |
| **ADR-011** | D13.1-D13.4 (existing LINE locale refresh; superseded as complete model by ADR-020), D12.x save/resume |
| **ADR-014** | Runtime/Presentation boundary (D20.2-D20.4) |
| **ADR-015** | Choice list display regions (D21.4) |
| **ADR-008 / ADR-009** | `get_display_value` interpolation (D8.5, D9.5) |
| **ADR-019** | D25.2 change gate |
| **04-runtime-and-integration.md** | Execution flows, presenter contract |
| **06-product-structure.md** | Localization resolution ownership wording |
| **07-presentation-product-spec.md** | Dialogue display surfaces |

## 6. Existing ADRs That Will Eventually Require Amendment

| ADR / Document | Why amendment will be needed |
|----------------|------------------------------|
| **ADR-002** | Phase behavior extension for locale switching |
| **ADR-006** | CHOICES and execution flows with localization guarantees |
| **ADR-010** | Presenter assumptions for localized step delivery |
| **ADR-011** | Clarify D13.x relationship to ADR-020/ADR B; retain D13.3 speaker behavior |
| **ADR-012** | Runtime/presentation localization verification expectations |
| **ADR-014** | Display vs translation-resolution ownership wording |
| **ADR-015** | Choice display vs localized delivery clarification |
| **ADR-020** | Cross-reference to contract ADRs (clarification) |
| **01-architecture-overview.md** | Phase and localization behavior |
| **04-runtime-and-integration.md** | Runtime localization flows |
| **05-open-questions.md** | D26.17, D26.18 resolution or continued deferral |
| **06-product-structure.md** | Ownership summary |
| **07-presentation-product-spec.md** | Presentation assumptions for localized text |

ADR A amendments are **prerequisite**, not produced by ADR B.

## 7. Architectural Questions That MUST Be Answered

*Listed for ADR B authorship. This planning document does not answer them.*

1. What runtime guarantee applies to localized **line body** text at `ConversationStep` delivery time?
2. What runtime guarantee applies to localized **choice label** text at `ConversationStep` delivery time?
3. What is the missing-translation contract when `TranslationServer` has no entry for a required identity?
4. What runtime obligations apply on `NOTIFICATION_TRANSLATION_CHANGED` for each phase in D26.10's table?
5. Specifically for `AwaitingChoice`, what does "refresh localized CHOICES delivery" mean at contract level without altering traversal semantics (D26.10)?
6. What locale-switch guarantee applies during `ExecutingCommand`, `Idle`, and `Ended` (extending D26.10)?
7. What locale behavior applies during `WAIT` steps (ADR-020 note referencing D6.5)?
8. What may Presentation assume about localized text on `ConversationStep` vs speaker `speaker_id` (D26.16)?
9. What is Presentation forbidden from doing regarding translation resolution (extending D26.9)?
10. What save/resume guarantee applies to localized display text (D26.11)?
11. Who owns translation catalog provisioning, locale selection, and missing-catalog detection?
12. Should D26.17 (choice-label interpolation) be resolved in ADR B, remain deferred, or be explicitly excluded?
13. Should D26.18 (locale refresh re-running interpolation) be resolved in ADR B, remain deferred, or be explicitly excluded?
14. What verification expectations apply at runtime/presentation/save-resume layers (per D26.14)?
15. Under what conditions does ADR B require changes to `IDialoguePresenter` contract?

## 8. Architectural Questions That MUST NOT Be Answered

ADR B must **not** answer (defer to ADR A or implementation):

1. How translation identity is stored in compiled data (ADR A).
2. Author-provided vs generated identity rules (ADR A).
3. Compiler validation algorithms or import failure mechanics (ADR A).
4. Concrete `ConversationStep` field names or option structure layout.
5. Concrete phase transition implementation.
6. `TranslationServer` method signatures or call sites.
7. Step-builder or presenter class design.
8. Serialization of compiled or snapshot data.
9. Numeric `format_version` values.
10. Golden snapshot file contents.
11. Test file names, test frameworks, or test case lists beyond architectural verification properties.

## 9. Proposed Decision Sections

*Section headings only. No decisions are recorded here.*

| Section | Topic |
|---------|--------|
| B.1 | Context and relationship to ADR-020 and ADR A |
| B.2 | Runtime localized delivery contract (compiled-identity text) |
| B.3 | `ConversationStep` localization semantics |
| B.4 | Missing-translation behavior contract |
| B.5 | Translation catalog and locale selection boundary |
| B.6 | Locale-switch contract by `ConversationPhase` |
| B.7 | Locale behavior during `WAIT` and non-presenter steps |
| B.8 | Presentation assumptions and prohibitions (including D26.16) |
| B.9 | Interpolation and locale refresh (D26.17, D26.18 resolution or deferral) |
| B.10 | Save/resume localization contract |
| B.11 | Runtime verification expectations |
| B.12 | Presentation verification expectations |
| B.13 | Consequences and required document amendments |
| B.14 | ADR-019 D25.2 gate statement |

## 10. Expected Invariants

*Invariants ADR B is expected to establish or restate. Not decided here.*

- Traversal coordinates (`line_id`, option targets, cursor) remain language-neutral during locale switch (D26.10).
- Localized display strings are not save data (D26.11).
- Runtime does not import Presentation (ADR-014 invariant).
- Presentation does not traverse `CompiledDialogue` for localization (D26.9).
- Speaker display remains Presentation-resolved via `speaker_id` unless a future ADR revisits D26.16.
- Locale switch does not restart in-flight command execution (D26.10 `ExecutingCommand`).
- Active locale at step construction/reconstruction time governs localized text delivery (D26.8).

## 11. Expected Ownership Boundaries

| Responsibility | Expected owner after ADR B |
|----------------|----------------------------|
| Resolving compiled-identity authored text | Runtime |
| Delivering localized text on `ConversationStep` | Runtime |
| Re-localizing visible steps on locale change | Runtime |
| Resolving speaker display name | Presentation (D26.16) |
| Displaying localized text and UX | Presentation |
| Interpolation values | Game via `GameContext` (delegated) |
| Translation catalogs and locale selection | Game / Godot project |
| Compiled identity preservation | Compiler/data per ADR A |

## 12. Expected Consequences

- ADR-002, ADR-006, ADR-010, ADR-011, ADR-014, ADR-015 and runtime/presentation architecture docs will require amendment.
- End-to-end choice-label localization becomes architecturally authorized only after **both** ADR A and ADR B are accepted.
- `AwaitingChoice` locale refresh becomes an authorized phase-behavior extension subject to D25.2.
- D26.17 and D26.18 will be either resolved or explicitly remain deferred with named future ADR owner.
- Implementation remains prohibited until ADR B acceptance and explicit D25.2 contract identification.

## 13. ADR-019 D25.2 Implications

ADR B is expected to **trigger D25.2** if accepted decisions change:

- `ConversationStep` delivery semantics for localized choice labels (and possibly LINE delivery clarification).
- `ConversationPhase` behavior for `AwaitingChoice` locale refresh (and possibly clarification of other phases).
- `IDialoguePresenter` contract **only if** accepted presentation assumptions cannot be satisfied without contract change (ADR-020 indicates speaker case does not require this).

ADR B must:

- Enumerate which gated contracts it changes upon acceptance.
- State that implementation of those changes is prohibited until ADR B is **Accepted**.
- Not design DTO layout, phase implementation, or presenter API.

ADR B is **not** expected to trigger D25.2 for:

- `CompiledLine` / `CompiledDialogue` (ADR A), unless ADR B discovers an ADR A gap—which would be a board escalation, not a design task here.

## 14. Dependencies on ADR A

| Dependency | Requirement |
|------------|-------------|
| **ADR A must be Accepted first** | ADR B's runtime contract references identity guarantees ADR A defines. |
| ADR B must not redefine identity | Identity origin, compiler duties, and compiled preservation belong to ADR A. |
| ADR B may reference ADR A invariants | e.g., "resolves identity established per ADR A." |
| If ADR A defers D26.17 | ADR B must state whether it resolves or inherits deferral for choice interpolation at delivery time. |

**Acceptance gate:** ADR B acceptance is **required** before implementation of runtime delivery, locale switching, or `ConversationStep` localization semantics. **Both** ADR A and ADR B must be Accepted before any end-to-end localized choice-label work begins.

---

# Cross-Cutting: Implementation Prohibitions

Until **ADR A** is Accepted, the following remain **prohibited**:

- Changing compiled localization identity representation.
- Changing compiler identity generation or validation behavior.
- Changing authoring identity expression for localized surfaces.
- Changing compiled-resource compatibility policy for localization identity.
- Updating golden compile expectations for new identity behavior.

Until **ADR B** is Accepted, the following remain **prohibited**:

- Changing `ConversationStep` localized delivery semantics.
- Implementing choice-label runtime localization.
- Implementing `AwaitingChoice` locale refresh.
- Changing locale-switch behavior for any phase.
- Changing save/resume localization behavior beyond existing D12.x.
- Changing presenter localization assumptions.
- Defining missing-translation runtime behavior in code.

Until **both** ADR A and ADR B are Accepted, the following remain **prohibited**:

- End-to-end choice-label localization.
- Any work presented as "ADR-020 implementation" that touches both compiled identity and runtime delivery.

---

# Board Review Checklist

Before authorizing ADR A or ADR B drafting, the board should confirm:

- [ ] ADR A and ADR B boundaries are correctly separated (identity vs delivery).
- [ ] D26.17 and D26.18 are assigned to ADR A, ADR B, or explicit continued deferral—not left implicit.
- [ ] D25.2 gated contracts are partitioned correctly between ADR A and ADR B.
- [ ] No planning section accidentally answers questions listed in §7.
- [ ] Acceptance sequence (A then B) is acceptable.
- [ ] Amendment blast radius is acceptable for each ADR.

---

*End of planning document. This is not an ADR. No implementation is authorized.*
