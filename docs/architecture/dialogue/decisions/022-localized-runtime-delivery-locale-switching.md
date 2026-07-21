# ADR 022: Localized Runtime Delivery and Locale Switching Contract

**Status:** Accepted  
**Date:** 2026-07-11  
**Decisions:** D28.1–D28.20  
**Extends:** ADR-020 (Localization Architecture), ADR-021 (Localized Authoring and Compiled Identity), ADR-002 (Runtime Architecture), ADR-006 (Runtime Execution), ADR-010 (UI and Presenter), ADR-011 (Save, Localization, and Debug), ADR-014 (Product Structure and Presentation), ADR-015 (Presentation Product Concepts)  
**Prerequisite:** ADR-021 **Accepted** (compile-time identity contract)  
**Clarifying amendments completed in:** ADR-002, ADR-006, ADR-010, ADR-011 (clarification), ADR-012, ADR-014, ADR-015, ADR-020 (cross-reference), `01-architecture-overview.md`, `04-runtime-and-integration.md`, `05-open-questions.md`, `06-product-structure.md`, `07-presentation-product-spec.md`

---

## Context

ADR-020 establishes the Localization subsystem: coverage model, ownership principles, runtime and presentation guarantees at philosophy level, locale-switch commitments by phase, save/resume language-neutrality, and D26.17/D26.18 (resolved by this ADR).

ADR-021 establishes the compile-time contract: translation identity, traversal identity distinction, compiler and compiled-data preservation obligations, and validation policy. Runtime delivery, locale switching, missing-translation behavior, `ConversationStep` semantics, Presentation localization assumptions, and save/resume runtime guarantees are **defined by this ADR**, not ADR-021.

This ADR defines the **localized runtime delivery and locale switching contract**. It answers:

> **What localization guarantees does Runtime provide during execution, what may Presentation assume, and what happens during locale switching and save/resume?**

This ADR is **Accepted**. Implementation of any change to gated contracts under ADR-019 D25.2 remains **prohibited** until implementation work is explicitly authorized under the change gate.

---

## Problem Statement

ADR-020 commits that:

- Choice labels are **Localized** with Runtime-owned translation resolution (**new**; not yet implemented).
- `AwaitingChoice` locale refresh is a **new guarantee** (D26.10).
- LINE locale refresh for `PresentingLine` / `AwaitingInput` is **existing** (ADR-011 D13.4).
- Speaker names remain Presentation-resolved (D26.16).
- Save/resume is language-neutral (D26.11).
- Interpolation values are **Delegated** to the game (D26.8-interpolation).
- D26.17 (choice-label interpolation) and D26.18 (locale-refresh interpolation) were **deferred in ADR-020** and are **resolved by this ADR** (D28.14, D28.15).

This ADR provides the runtime delivery contract required to implement those commitments without inventing semantics ad hoc.

---

## Scope

This ADR defines architectural contracts for:

- Runtime localization resolution and delivery for compiled-identity authored text (line body, choice labels).
- `ConversationStep` localization semantics (contract level, not layout).
- Missing-translation behavior.
- Locale-switch behavior for every `ConversationPhase` (ADR-002 D2.3).
- Locale behavior during `WAIT` steps (ADR-006 D6.5).
- Presentation assumptions and prohibitions (extending ADR-020 D26.9; retaining D26.16).
- Save/resume localization guarantees (extending ADR-020 D26.11).
- Translation catalog and locale selection boundary.
- Resolution of D26.17 and D26.18 at architectural level.
- Runtime and presentation architectural verification expectations.
- ADR-019 D25.2 gated runtime contract identification.

---

## Explicit Non-Scope

This ADR must **not** define:

- Authoring syntax, compiler identity generation, or compiled schema layout (ADR-021).
- Concrete `ConversationStep` field names, option structure layout, or serialization.
- Concrete phase transition implementation or step-builder algorithms.
- Translation catalog file formats, registration mechanics, or translation-infrastructure API call sites.
- Translation authoring tools, machine translation, or translation management (ADR-020 D26.15).
- Game UI outside dialogue conversations or game-mode UI from commands.
- Portrait, screen-reader, or narration localization (deferred per ADR-020).
- Presentation typewriter, theme, policy, or input mechanics except as they consume localized strings.
- Migration, reimport, or loader implementation.
- Test file names, frameworks, or test case lists beyond architectural verification properties.

---

## Definitions (D28.1)

| Term | Meaning in this ADR |
|------|---------------------|
| **Compiled-identity authored text** | Player-visible authored **text** classified as Localized in ADR-020 D26.4 whose translation identity is established per ADR-021 (LINE body, choice labels in v1). |
| **Localized delivery** | The runtime act of producing a display-ready string for a compiled-identity authored text surface in the active locale at step construction or reconstruction time. |
| **Active locale** | The locale the game's translation infrastructure considers active at the moment Runtime constructs or reconstructs a delivery artifact. Locale selection is game/project policy (ADR-020 D26.5). |
| **Locale refresh** | Runtime reconstruction and re-delivery of the currently visible localized step when the active locale changes during an in-progress conversation, without altering traversal semantics. |
| **Traversal semantics** | Graph coordinates and execution rules: `line_id`, option targets, cursor position, phase transitions, condition evaluation, command execution — all language-neutral. |
| **Translation identity** | Per ADR-021; Runtime resolves catalogs using translation identity, not traversal identity. |
| **Delegated interpolation value** | Dynamic game state inserted into localized text at delivery time per ADR-020 D26.8-interpolation; owned by the game via `GameContext`. |

### Rationale

Shared vocabulary prevents conflating delivery, identity, traversal, and locale policy.

### Alternatives considered

- Rely on ADR-020 terminology only. Rejected because contract ADRs must be self-contained for review.

### Consequences

- Amendments use these terms consistently; they do not introduce new identity concepts.

---

## Status of Commitments — Existing / New / Deferred (D28.2)

| Commitment | Status | Decision |
|------------|--------|----------|
| Runtime resolves compiled-identity LINE body text | **Existing** (ADR-011 D13.1); contract formalized here | D28.4, D28.5 |
| Locale refresh for `PresentingLine` / `AwaitingInput` | **Existing** (ADR-011 D13.4) | D28.10 |
| Speaker display via Presentation `tr(speaker_id, "speakers")` | **Existing** (ADR-011 D13.3, ADR-020 D26.16) | D28.6 |
| Language-neutral save/resume coordinates | **Existing** (ADR-011 D12.x, ADR-020 D26.11) | D28.13 |
| Runtime delivers localized choice labels | **New** | D28.4, D28.5 |
| `AwaitingChoice` locale refresh | **New** | D28.10, D28.12 |
| Locale guarantees for `Idle`, `ExecutingCommand`, `Ended` | **New** (ADR-020 D26.10) | D28.10 |
| Missing-translation architectural policy | **New** (explicit contract) | D28.8 |
| Runtime policy for architecturally incomplete CHOICE resources | **New** (ADR-021 D27.11; defined here D28.9) | D28.9 |
| D26.17 choice-label interpolation | **Resolved — excluded in v1** | D28.14 |
| D26.18 locale-refresh interpolation re-resolution | **Resolved** | D28.15 |
| Portrait / narration / custom line type localization | **Deferred** | D28.20 |

### Rationale

Distinguishes inherited behavior from new guarantees so implementers do not mistake proposals for shipped semantics.

### Alternatives considered

- Omit status tagging. Rejected per ADR-020 D26.1b precedent.

### Consequences

- Implementation planning must tag work items against Existing vs New.

---

## Architectural Invariants (D28.3)

The following invariants govern all decisions in this ADR.

1. **Traversal language-neutrality** — Locale change must never alter traversal semantics: `line_id`, option target IDs, visible-option filtering results, cursor, phase (except redelivery), or command execution in flight.
2. **Save language-neutrality** — Localized display strings are not save data; snapshots persist coordinates only (ADR-020 D26.11, ADR-021 D27.1 #6).
3. **No runtime source parsing** — Runtime does not parse `.dlg` authoring source in production (ADR-003, ADR-021 D27.1 #4).
4. **Compiled resources language-neutral** — Runtime reads identity and authoring-language source text from compiled data; it does not treat compiled nodes as pre-localized artifacts (ADR-021 D27.1 #1, #7).
5. **Runtime does not import Presentation** — ADR-014 invariant preserved.
6. **Presentation does not localize compiled-identity text** — Presentation displays Runtime-delivered strings; speaker name is the sole Presentation translation-resolution case (ADR-020 D26.16).
7. **Identity consumption, not redefinition** — Runtime consumes translation identity per ADR-021; this ADR does not alter compile-time identity rules.
8. **Active locale governs delivery** — Localized delivery uses the active locale at step construction or reconstruction time (ADR-020 D26.8).

### Rationale

Restates cross-layer invariants so this ADR is reviewable without assembling ADR-020 and ADR-021.

### Alternatives considered

- State invariants only in ADR-020. Rejected for contract ADR self-containment.

### Consequences

- All runtime and presentation amendments must preserve these invariants.

---

## Decision D28.4 — Runtime Localized Delivery Contract

### Context

ADR-020 D26.8 assigns Runtime ownership of localization resolution for compiled-identity authored text. ADR-021 guarantees translation identity and authoring-language source text on compiled nodes for in-scope surfaces. ADR-011 D13.1 establishes LINE resolution via the project's translation infrastructure.

### Decision

**Runtime owns localized delivery** for all compiled-identity authored text surfaces in scope of ADR-021.

For each such surface at step construction or reconstruction time, Runtime **must**:

1. Read **translation identity** from compiled data (not traversal identity).
2. Resolve the active-locale display string through the game's translation infrastructure bound to the active locale.
3. Apply **delegated interpolation value placement** for LINE body text where authoring permits placeholders (existing ADR-008/ADR-009 delegation); choice labels remain static text in v1 (D28.14).
4. Deliver the resulting **presentation-ready localized string** on the runtime delivery artifact for that surface.

**Presentation-ready** means Runtime delivers localized authored text; Presentation remains responsible for rendering and display behavior, including BBCode and related display responsibilities already established by ADR-010.

Runtime **must not**:

- Resolve speaker display names (Presentation, D26.16).
- Author, register, or select translation catalogs (game/project).
- Parse `.dlg` source text.
- Use traversal identity as the catalog lookup key unless translation identity equals traversal identity by author/compiler policy (ADR-021 D27.3).

**LINE body** and **choice labels** receive the **same delivery contract** in v1: resolve by translation identity, deliver localized string, preserve traversal fields separately.

### Rationale

Single delivery model aligns with ADR-020 model B and ADR-021 unified identity concept.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Presentation resolves choice labels** | Violates ADR-020 D26.4/D26.5; fragments ownership. |
| **Game pre-translates before Runtime** | Runtime owns compiled dialogue and step construction. |
| **Deliver translation identity as display text** | Violates language-neutrality and user-facing delivery contract. |

### Consequences

- ADR-006 and `04-runtime-and-integration.md` require amendment for CHOICES delivery guarantees.
- ADR-019 D25.2 implicated for `ConversationStep` CHOICES delivery semantics.

---

## Decision D28.5 — ConversationStep Localization Contract

### Context

ADR-003 defines `ConversationStep` kinds including `LINE` and `CHOICES`. ADR-010 defines `IDialoguePresenter.present(step)`. ADR-020 requires Runtime to deliver localized text through runtime delivery contracts without designing DTO layout here.

### Decision

At the **architectural contract level**, `ConversationStep` localization responsibilities are:

| Step kind | Runtime delivers | Runtime does not deliver | Presentation receives |
|-----------|------------------|--------------------------|------------------------|
| **`LINE`** | Localized line body display text | Localized speaker display name | Localized body text + language-neutral `speaker_id` |
| **`CHOICES`** | Localized label for each visible option | — | Localized option labels + language-neutral option targets and indices |
| **`COMMAND`** | — (no compiled-identity authored text) | — | Command payload per existing ADRs |
| **`WAIT`** | — (no authored text displayed) | — | No presenter involvement (D6.5) |
| **`END`** | — | — | End signal per existing ADRs |

Rules:

1. **Localized strings on the step are presentation-ready** for compiled-identity authored text surfaces — Presentation does not perform catalog lookup for line body or choice labels.
2. **Traversal and structural fields remain language-neutral** — `line_id`, option `target_line_id`, indices, tags, command identifiers.
3. **`speaker_id` on LINE steps** is delivered language-neutral for Presentation speaker resolution (D26.16).
4. Locale refresh **reconstructs** the same step kind for the same traversal coordinates with updated localized strings (D28.10).

This ADR **does not** define field names, member layout, or serialization.

### Rationale

Separates delivery obligations from DTO design while giving implementers and presenter authors an unambiguous contract.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Define DTO fields in this ADR** | Violates non-scope; ADR-019 D25.2 implementation designs layout. |
| **Separate delivery contract per presenter** | Violates framework guarantee for choice labels. |

### Consequences

- ADR-019 D25.2 triggered for `ConversationStep` delivery semantics (CHOICES localized labels; LINE clarification).
- ADR-010 and ADR-015 require amendment for presenter assumptions.

---

## Decision D28.6 — Presentation Assumptions and Prohibitions

### Context

ADR-020 D26.9 states presentation guarantees at philosophy level. ADR-014 separates Runtime and Presentation. ADR-010 D11.4 assigns speaker `tr()` to Presentation.

### Decision

**Presentation may assume:**

1. Line body text and choice option labels on delivered steps are **already localized** for the active locale at delivery time.
2. Delivered localized text is **presentation-ready** for display (subject to Presentation overflow, BBCode, and accessibility policy).
3. **`speaker_id` on LINE steps** is the language-neutral key for speaker display name resolution in Presentation (D26.16).
4. Identity, traversal, condition, and phase semantics are **Runtime concerns**.
5. A locale refresh triggers a fresh `present(step)` with updated localized strings **without** traversal coordinate changes (D28.10).
6. Typewriter restart, continuation, or hold behavior on locale refresh is **Presentation policy** unless a future ADR specifies otherwise (consistent with ADR-020 D26.10 note on `PresentingLine`).

**Presentation must continue to own:**

- Rendering, layout, styling, typewriter, timing policy, input, choice navigation UX, and accessibility behavior.
- Speaker display name resolution via `tr(speaker_id, "speakers")`.
- Display of localized strings without mutating their language content.

**Presentation is forbidden from:**

- Traversing `CompiledDialogue` to resolve compiled-identity authored text.
- Performing translation catalog lookup for line body or choice labels.
- Mutating conversation phase or cursor except through public Runtime APIs.
- Creating a parallel localization identity model for authored dialogue text.

**Runtime must never own:**

- Speaker display name resolution.
- Presentation rendering, theme, layout, or input UX.
- Translation catalog authoring or locale selection policy.
- Game command UI localization.
- Delegated interpolation value content or formatting (game owns values).

### Rationale

Preserves ADR-020 D26.5 identity-mechanism split and ADR-014 boundaries.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Move speaker resolution to Runtime** | Rejected in ADR-020 D26.16. |
| **Let presenters optionally skip choice localization** | Violates framework guarantee. |

### Consequences

- `07-presentation-product-spec.md` and ADR-015 require amendment.
- **`IDialoguePresenter` contract change is not required** for v1 if localized strings are supplied on steps as defined here (see D28.18).

---

## Decision D28.7 — Translation Catalog and Locale Selection Boundary

### Context

ADR-020 D26.5 assigns translation catalog content and locale selection to game/Godot project. Runtime must consume catalogs without owning provisioning.

### Decision

| Responsibility | Owner |
|----------------|-------|
| Authoring translation catalog content | Game / Godot project |
| Registering catalogs with the project's translation infrastructure | Game / Godot project |
| Selecting active locale | Game / Godot project |
| Detecting missing catalog entries at project level | Game / Godot project (framework does not mandate CI policy) |
| Resolving a localized string for a translation identity at delivery time | **Runtime** |
| Choosing fallback when resolution fails | **Runtime** (policy in D28.8) |

Runtime **must** use the **active locale** at step construction or reconstruction time. Runtime **must not** embed locale selection policy or catalog registration logic.

This ADR does not define catalog formats, registration APIs, or locale-switch triggers.

### Rationale

Keeps Runtime headless and defers project integration to games while making resolution ownership explicit.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Framework-owned locale selection** | Outside product boundary; games own settings. |
| **Runtime registers default catalogs** | Violates ADR-020 non-goals. |

### Consequences

- Integration guides document game responsibilities; `06-product-structure.md` amendment clarifies boundary.

---

## Decision D28.8 — Missing Translation Architectural Policy

### Context

ADR-020 D26.8 states Runtime does not guarantee catalogs contain every identity. ADR-021 preserves authoring-language source text on compiled nodes for debug/fallback. A contract-level policy is required.

### Decision

When translation infrastructure resolution **fails** to produce a localized string for a required translation identity at delivery time, Runtime **must** fall back to the **compiled authoring-language source text** preserved for that localized text surface (ADR-021 D27.9).

Rules:

1. Fallback uses compiled data only — no `.dlg` parsing.
2. Fallback applies identically to LINE body and choice labels.
3. Fallback is **not** a traversal semantic change.
4. Runtime **may** surface diagnostics in debug builds; diagnostic mechanics are not defined here.
5. Runtime **must not** use translation identity, traversal identity, or empty string as the player-facing fallback except where authoring-language source text is empty (empty display is acceptable when source is empty).

### Rationale

Uses ADR-021 preservation obligation; enables graceful degradation without runtime source parsing; consistent across surfaces.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Hard error / halt conversation** | Too brittle for shipped games with incomplete catalogs. |
| **Display translation identity** | Not user-facing text; leaks implementation detail. |
| **Empty string always** | Poor UX when source text exists in compiled data. |
| **Presentation decides fallback** | Violates Runtime ownership of compiled-identity delivery. |

### Consequences

- Runtime verification must cover fallback path (D28.16).
- Games remain responsible for catalog completeness; framework guarantees deterministic degradation.

---

## Decision D28.9 — Architecturally Incomplete Compiled Resources

### Context

ADR-021 D27.11 states resources compiled before the choice-identity contract may lack choice-label translation identity and are architecturally incomplete for localized choice delivery. Runtime/load policy is **defined by this ADR (D28.9)**.

### Decision

For **CHOICE** nodes in compiled resources **architecturally incomplete** per ADR-021 D27.11 (missing required translation identity):

1. Runtime **must not** infer translation identity from authoring source at runtime.
2. Runtime **must** deliver the **compiled authoring-language source text** as the choice label display string (same string source as D28.8 fallback).
3. Runtime **must not** treat such resources as satisfying the **new** localized choice-label guarantee; behavior is **degraded** until reimport under ADR-021 contract.
4. Runtime **may** surface diagnostics in debug builds when serving incomplete resources.

For **LINE** nodes, existing identity remains valid per ADR-021; this policy does not apply.

Remediation remains **reimport** per ADR-021 — not a runtime migration procedure.

### Rationale

Aligns incomplete-resource behavior with missing-translation fallback using preserved source text; avoids runtime identity invention.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Hard fail on load** | Overly brittle; breaks games with legacy `.tres` until reimport. |
| **Runtime-generate identity from source** | Violates ADR-021 compiler ownership and no-runtime-parsing invariant. |
| **Silent catalog lookup by source text** | No stable identity; breaks translation pipeline model. |

### Consequences

- Games should reimport dialogue after framework upgrade implementing ADR-021.
- Verification must cover degraded CHOICE path (D28.16).

---

## Decision D28.10 — Locale Switching by ConversationPhase

### Context

ADR-020 D26.10 defines locale-switch guarantees per phase. ADR-002 D2.3 enumerates phases. ADR-011 D13.4 covers LINE refresh only. this ADR must make the full table normative at contract level.

### Decision

On **active locale change** during an in-progress conversation, Runtime **must** honor the following guarantees. **Traversal semantics must not change.**

| Phase | Localization guarantee | Status |
|-------|------------------------|--------|
| **`Idle`** | No active step. Next `start()` or `resume()` uses active locale at that time. | **New** |
| **`PresentingLine`** | Locale refresh: reconstruct and re-deliver the visible localized LINE step for the current `line_id`; cursor and phase unchanged; call `present(step)` with updated localized body text. | **Existing** (D13.4) |
| **`AwaitingInput`** | Same as `PresentingLine` for the current LINE step. | **Existing** (D13.4) |
| **`AwaitingChoice`** | Locale refresh: reconstruct and re-deliver the visible localized CHOICES step for the current `line_id` without changing option order, option target IDs, visible-option filtering result, cursor, or phase; call `present(step)` with updated localized option labels; **and** update the co-visible prompting LINE via `refresh_line_text` when prompting LINE identity is known (ADR-023 D29.1–D29.3). | **Amended by ADR-023** |
| **`ExecutingCommand`** | Do not restart or re-enter the executing command. Next Dialogue Framework step after completion uses active locale at that time. | **New** |
| **`Ended`** | No active localized step guaranteed. Cleanup to `Idle` under existing rules. | **New** |

**Locale refresh** means: rebuild the delivery artifact for the currently visible step using the new active locale, then re-present through the presenter contract.

This ADR does not mandate a specific locale-change detection mechanism.

### Rationale

Completes ADR-020 phase table as binding contract; extends D13.4 to choices and remaining phases.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **LINE phases only** | Leaves choice UI stale on locale change. |
| **Restart conversation on locale change** | Violates traversal invariants. |

### Consequences

- ADR-002 and ADR-006 require amendment for `AwaitingChoice` refresh.
- ADR-019 D25.2 implicated for `ConversationPhase` behavior extension.

---

## Decision D28.11 — Locale Behavior During WAIT and Non-Presenter Steps

### Context

ADR-006 D6.5 yields `WAIT` steps without presenter involvement. ADR-020 notes locale behavior during `WAIT` inherits from surrounding phase.

### Decision

1. **`WAIT` steps** display no authored localized text and invoke no presenter. **No locale-refresh action** is required during an in-flight `WAIT` step.
2. When a `WAIT` step completes and Runtime produces the next visible step, that step **must** use the **active locale at production time**.
3. If locale changes during `WAIT`, any subsequent visible step after `WAIT` completes **must** reflect the then-active locale.
4. **`COMMAND` steps** with no compiled-identity authored text require no locale refresh; game-owned command UI localization remains delegated to the game.

### Rationale

Consistent with ADR-020 `@wait` note; avoids inventing a wait-phase display contract.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Define wait-phase locale refresh** | No displayed authored text in v1. |
| **Cancel WAIT on locale change** | Alters execution semantics. |

### Consequences

- No new phase enum required for v1.

---

## Decision D28.12 — AwaitingChoice Locale Refresh Contract

### Context

ADR-020 D26.10 commits `AwaitingChoice` refresh without designing mechanics. Planning question 5 requires contract-level precision.

### Decision

**"Refresh localized CHOICES delivery"** means:

1. **Preserve** traversal state: current `line_id`, option order, each option's `target_line_id`, visible-option set after condition filtering, Runtime-owned conversation selection index (the index used by `ConversationController.choose()`), and `AwaitingChoice` phase. This preservation guarantee applies only to Runtime-owned conversation selection state; it does not redefine Presentation UX ownership of highlight, focus, or visual choice navigation.
2. **Re-resolve** localized label strings for every **visible** option using each option's translation identity per ADR-021.
3. **Reconstruct** the CHOICES delivery artifact with updated localized labels and unchanged structural fields.
4. **Re-present** via `present(step)` without requiring player re-selection.
5. **Co-visible prompting LINE (ADR-023):** When prompting LINE soft state is non-empty, rebuild that LINE and deliver it via `IDialoguePresenter.refresh_line_text(step)` without changing `_current_step` away from CHOICES or altering choice structural fields.

Runtime **must not** re-run traversal, re-filter on different criteria, or change option targets during locale refresh.

### Rationale

Makes the ADR-020 guarantee testable without prescribing algorithms.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Dismiss and rebuild from cursor** | Risks traversal side effects if not carefully bounded; full reconstruct is clearer. |
| **Presentation re-localizes labels** | Violates ownership. |

### Consequences

- ADR-019 D25.2 implicated for phase behavior and CHOICES step reconstruction.

---

## Decision D28.13 — Save and Resume Localization Contract

### Context

ADR-020 D26.11 and ADR-011 D12.x establish coordinate-based snapshots. this ADR must state runtime obligations on resume.

### Decision

**Save guarantees (restated as runtime contract):**

1. `DialogueSnapshot` persists **coordinates only** — `resource_uid`, `entry_label`, `line_id` (ADR-011 D12.2).
2. Active locale is **not** part of snapshot data.
3. Localized display strings are **not** persisted in snapshot or game save data.

**Resume guarantees:**

1. `resume()` uses **traversal identity only** (`line_id`); `entry_label` is debug/metadata (ADR-011 D12.5).
2. Runtime rebuilds localized delivery from compiled data using **active locale at resume time**.
3. Resume **must not** require the locale at save time to match the locale at resume time.
4. Resume **must not** replay stale localized strings from a previous session locale.
5. Re-presented line content after resume starts from the beginning per ADR-011 D12.3 (Presentation handles re-display).

### Rationale

Preserves language-neutral save model while making localization obligations explicit at runtime boundary.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Store locale in snapshot** | Locale is game policy, not dialogue progress. |
| **Store localized strings** | Makes saves locale-specific and translation-update fragile. |

### Consequences

- ADR-011 amendment clarifies D12.x vs ADR-020/this ADR relationship.
- Save/resume verification properties in D28.16.

---

## Decision D28.14 — Choice-Label Interpolation (D26.17)

### Context

ADR-020 D26.17 deferred whether choice labels may contain runtime interpolation. ADR-021 D27.6 bounds identity to static authored label text; delivery semantics are **defined by this ADR (D28.14)**. Authoring format documents `{brace}` interpolation on dialogue lines only.

### Decision

**Resolve D26.17 for v1: choice-label interpolation is excluded.**

1. Choice labels are delivered as **localized static text** per D28.4 and D28.5.
2. Runtime **must not** apply delegated interpolation placeholder resolution to choice labels in v1.
3. Permitting interpolation in choice labels requires a **future ADR** that defines authoring classification, placement ownership, interaction with translation identity, and any ADR-019 D25.2 implications.

Until such ADR: authored choice labels are architecturally treated as **static text surfaces** at delivery time.

### Rationale

Closes deferral without inventing syntax; consistent with ADR-021 static boundary and current authoring documentation.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Permit choice interpolation in this ADR** | Would require authoring and delivery rules not in accepted ADR-004. |
| **Leave fully deferred** | Planning requires this ADR to resolve or explicitly defer; exclusion is a resolution. |
| **Forbid permanently** | Future ADR may permit with explicit design. |

### Consequences

- `05-open-questions.md` records D26.17 as resolved for v1 (excluded).
- D28.15 CHOICE interpolation refresh is N/A in v1.

---

## Decision D28.15 — Locale Refresh and Interpolation Re-Resolution (D26.18)

### Context

ADR-020 D26.18 deferred whether locale refresh re-invokes delegated value resolution for interpolation placeholders in line body text.

### Decision

**Resolve D26.18:**

When Runtime performs **locale refresh** that reconstructs a visible **LINE** step (D28.10 `PresentingLine` / `AwaitingInput`):

1. Runtime **must** re-resolve the localized line body string for the new active locale.
2. Runtime **must** re-resolve **delegated interpolation placeholder values** through the game's delegated mechanism at reconstruction time, so locale-sensitive game values can update.

When Runtime performs locale refresh for **CHOICES** steps: only localized static label strings are re-resolved (D28.14); no interpolation re-resolution applies in v1.

### Rationale

Locale refresh that updates translated text but freezes dynamic game values would produce inconsistent display for locale-sensitive delegated values.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Do not re-resolve interpolation on refresh** | Stale dynamic values after locale change. |
| **Defer D26.18 further** | Planning requires resolution in this ADR. |
| **Re-resolve interpolation on CHOICE refresh** | N/A while D26.17 excluded. |

### Consequences

- `05-open-questions.md` records D26.18 as resolved.
- Locale-refresh verification must cover LINE interpolation re-resolution (D28.16).

---

## Decision D28.16 — Runtime Architectural Verification Expectations

### Context

ADR-020 D26.14 and ADR-012 require verifiable architecture. ADR-021 covers compile-time properties; this ADR covers runtime delivery and locale switching.

### Decision

The following properties **must** be verifiable at the runtime architectural layer (verification mechanics are ADR-012; not defined here):

| Property | Layer |
|----------|-------|
| LINE steps deliver localized body text for active locale when identity resolves | Runtime |
| CHOICES steps deliver localized labels for each visible option when identities resolve | Runtime |
| Missing catalog entry falls back to compiled authoring-language source text | Runtime |
| Architecturally incomplete CHOICE nodes deliver source text without runtime identity inference | Runtime |
| Locale refresh in `PresentingLine` / `AwaitingInput` updates LINE text without traversal change | Runtime |
| Locale refresh in `AwaitingChoice` updates option labels without traversal change | Runtime |
| `ExecutingCommand` does not restart on locale change | Runtime |
| Resume rebuilds localized delivery from active locale at resume time | Runtime / save integration |
| Snapshot contains no localized display strings | Save contract |
| Runtime does not traverse `CompiledDialogue` for localization during delivery | Runtime |
| LINE locale refresh re-resolves delegated interpolation values (D28.15) | Runtime |

### Rationale

Implements ADR-020 D26.14 scoped to delivery, locale switch, and save/resume.

### Alternatives considered

- Defer verification to game smoke tests only. Rejected per ADR-020 D26.14.

### Consequences

- ADR-012 amendment expands runtime verification list.

---

## Decision D28.17 — Presentation Architectural Verification Expectations

### Context

ADR-020 D26.14 requires Presentation-layer verification. this ADR defines assumptions without UI implementation.

### Decision

The following properties **must** be verifiable at the presentation architectural layer:

| Property | Layer |
|----------|-------|
| Presentation displays Runtime-delivered localized line body and choice labels without catalog lookup | Presentation |
| Presentation resolves speaker display name from `speaker_id` independently of line body localization | Presentation |
| Presentation does not traverse `CompiledDialogue` for authored text localization | Presentation |
| `present(step)` after locale refresh displays updated localized strings | Presentation integration |
| Typewriter/UX policy on refresh does not alter traversal (cursor/phase owned by Runtime) | Presentation integration |

### Rationale

Confirms Presentation honors D28.6 without prescribing UI tests.

### Consequences

- ADR-012 amendment expands presentation verification list.

---

## Decision D28.18 — ADR-019 D25.2 Change Gate

### Context

ADR-019 D25.2 requires explicit ADR before gated contract changes. ADR-020 enumerated runtime blast radius. ADR-021 addressed compiled-data gates.

### Decision

Acceptance of this ADR **authorizes the architectural runtime contract** that implementation must satisfy. **Implementation remains prohibited** until:

1. This ADR is **Accepted**, and  
2. **ADR-021** is **Accepted**, and  
3. Implementation work explicitly addresses ADR-019 D25.2-gated contracts below.

**Gated contracts implicated by this ADR:**

| Gated contract (ADR-019 D25.2) | Why implicated |
|--------------------------------|----------------|
| `ConversationStep` delivery semantics | Localized choice labels on CHOICES steps; LINE delivery contract formalized |
| `ConversationPhase` behavior | `AwaitingChoice` locale refresh; `Idle` / `ExecutingCommand` / `Ended` guarantees |

**Not implicated by this ADR for v1:**

| Gated contract | Why not |
|----------------|---------|
| `CompiledLine` / `CompiledDialogue` | ADR-021 scope |
| `IDialoguePresenter` | v1 contract satisfied by localized strings on existing `present(step)` delivery; no presenter API change required for CHOICES/LINE present. **Amended by ADR-023:** `refresh_line_text` authorized for co-visible prompting LINE during `AwaitingChoice` locale refresh. |
| Compiler pipeline | ADR-021 scope |

**End-to-end localized choice-label delivery** requires **both** ADR-021 and this ADR **Accepted**, plus D25.2-gated implementation for **both** compiled identity (ADR-021) and runtime delivery (this ADR).

This ADR **does not design** DTO layout, phase implementation, presenter API, or lookup algorithms.

### Rationale

Separates architectural acceptance from implementation; partitions gates correctly with ADR-021.

### Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| **Gate presenter contract preemptively** | ADR-020 indicates speaker case does not require it; localized strings on steps suffice. |
| **Single gate for ADR-020 only** | Contract ADRs partition compile-time vs runtime gates. |

### Consequences

- Implementation planning must cite ADR-021, this ADR, and D25.2.
- No implementation authorized by this ADR alone.

---

## Decision D28.19 — Ownership Boundaries

### Context

ADR-020 D26.5 assigns high-level ownership. Decisions D28.4–D28.15 distribute responsibilities across Runtime, Presentation, Game, and ADR-021 compile-time artifacts. A single consolidated table aids review and amendment tracking.

### Decision

| Responsibility | Owner |
|----------------|-------|
| Translation identity generation and validation | Compiler (ADR-021) |
| Preserving identity and authoring-language source in compiled data | Compiled data contract (ADR-021) |
| Resolving compiled-identity authored text for active locale | **Runtime** |
| Delivering localized strings on `ConversationStep` | **Runtime** |
| Missing-translation fallback policy | **Runtime** (D28.8) |
| Locale refresh / re-localization of visible steps | **Runtime** (D28.10, D28.12) |
| Re-resolving delegated interpolation values on LINE locale refresh | **Runtime** (D28.15) |
| Resolving speaker display name | **Presentation** (D26.16) |
| Displaying localized text, UX, layout, typewriter, input | **Presentation** |
| Delegated interpolation values | **Game** via `GameContext` |
| Translation catalogs and active locale selection | **Game / Godot project** |
| Save/resume coordinates | **Game** embeds `DialogueSnapshot`; Runtime produces localized delivery on resume |
| Traversal semantics | **Runtime** |

### Rationale

Restates ownership from prior decisions in one place without altering the ADR-020 identity-mechanism split or ADR-014 boundaries.

### Consequences

- `06-product-structure.md` amendment clarifies localization resolution ownership using this table.
- No ownership change relative to D28.6, D28.7, or ADR-020 D26.5/D26.16.

---

## Decision D28.20 — Explicit Deferrals

### Context

this ADR must not absorb ADR-021 compile-time responsibilities or implementation design. Planning outline and board boundary review require an explicit deferral register.

### Decision

The following remain **outside this ADR**:

| Topic | Deferred to |
|-------|-------------|
| Compile-time identity, fallback, uniqueness, validation | **ADR-021** (Accepted) |
| Choice-label interpolation in authoring/delivery (beyond v1 exclusion) | **Future ADR** |
| Portrait, screen-reader, narration localization | **Future ADRs** per ADR-020 |
| `SpeakerManifest` / compiled speaker identity | **Future ADR** per 05-open-questions |
| Translation catalog formats and registration mechanics | **Game / Godot project** |
| Concrete `ConversationStep` layout and presenter API | **Implementation** under D25.2 |
| Numeric schema versions and loader behavior | **Implementation** under ADR-021 D25.2 |
| Presentation typewriter restart policy on locale refresh (beyond Presentation policy note) | **Presentation policy** unless future ADR |

### Rationale

Preserves ADR-021 / ADR-022 separation and documents topics intentionally excluded from runtime contract authorship.

### Consequences

- Acceptance of this ADR alone does not authorize compile-time identity work (ADR-021) or implementation of deferred surfaces.
- `05-open-questions.md` records D26.17/D26.18 closure and remaining deferred topics.

---

## Summary Table — Runtime Contract at a Glance

| Topic | Decision |
|-------|----------|
| Runtime delivery | Localized strings for LINE body + choice labels by translation identity |
| ConversationStep | Runtime delivers localized text; Presentation receives `speaker_id` unresolved |
| Missing translation | Fallback to compiled authoring-language source text |
| Incomplete CHOICE resources | Degraded: source text delivery; reimport remediation |
| Locale refresh | All phases per D28.10; `AwaitingChoice` per D28.12 |
| WAIT steps | No refresh during WAIT; next step uses then-active locale |
| D26.17 | **Excluded in v1** (static choice labels) |
| D26.18 | **Resolved**: LINE refresh re-resolves interpolation values |
| Save/resume | Coordinates only; resume uses active locale at resume time |
| Catalogs / locale | Game/project owns; Runtime consumes active locale |
| Presenter contract | **No change required** for v1 |
| D25.2 gates | `ConversationStep`, `ConversationPhase` |

---

## Consequences (Overall)

- Clarifying amendments to **ADR-002**, **ADR-006**, **ADR-010**, **ADR-011** (clarification), **ADR-012**, **ADR-014**, **ADR-015**, **ADR-020** (cross-reference), and architecture docs **`01-architecture-overview.md`**, **`04-runtime-and-integration.md`**, **`05-open-questions.md`**, **`06-product-structure.md`**, **`07-presentation-product-spec.md`** are **completed**.
- **End-to-end choice-label localization** is architecturally authorized with **ADR-021 and this ADR** (both **Accepted**), subject to D25.2-gated implementation.
- **D26.17** and **D26.18** are resolved for v1 per D28.14 and D28.15; `05-open-questions.md` records closure.
- **Implementation remains governed by ADR-019 D25.2**; acceptance of this ADR does not authorize implementation execution.
- ADR-021 compile-time contract is consumed, not modified, by this ADR.

---

## Architecture Review Board Checklist

- [x] ADR-022 boundaries correctly separated from ADR-021 (identity vs delivery).
- [x] D26.17 resolved (v1 exclusion) and D26.18 resolved (LINE refresh re-resolution).
- [x] D25.2 gated contracts partitioned: compiled (ADR-021) vs runtime (this ADR).
- [x] Every `ConversationPhase` has locale-switch guarantee (D28.10).
- [x] Presentation speaker ownership preserved (D28.6, D26.16).
- [x] Save/resume language-neutrality preserved (D28.13).
- [x] No implementation, schema, DTO, API, or algorithm design in ADR text.
- [x] Missing-translation and incomplete-resource policies explicit.
- [x] Amendment blast radius acceptable.

---

## References

- [020-localization-architecture.md](020-localization-architecture.md) — ADR-020
- [021-localized-authoring-compiled-identity.md](021-localized-authoring-compiled-identity.md) — ADR-021
- [002-runtime-architecture.md](002-runtime-architecture.md) — ADR-002
- [006-runtime-execution.md](006-runtime-execution.md) — ADR-006
- [010-ui-and-presenter.md](010-ui-and-presenter.md) — ADR-010
- [011-save-localization-debug.md](011-save-localization-debug.md) — ADR-011
- [012-validation-tooling-testing.md](012-validation-tooling-testing.md) — ADR-012
- [014-product-structure-and-presentation.md](014-product-structure-and-presentation.md) — ADR-014
- [015-presentation-product-concepts.md](015-presentation-product-concepts.md) — ADR-015
- [019-presentation-growth-constraints.md](019-presentation-growth-constraints.md) — ADR-019 D25.2
- [../planning/localization-contract-adrs-outline.md](../planning/localization-contract-adrs-outline.md)
- [../04-runtime-and-integration.md](../04-runtime-and-integration.md)
- [../06-product-structure.md](../06-product-structure.md)
- [../07-presentation-product-spec.md](../07-presentation-product-spec.md)
