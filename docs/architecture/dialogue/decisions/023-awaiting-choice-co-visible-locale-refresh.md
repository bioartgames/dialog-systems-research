# ADR 023: AwaitingChoice Co-Visible Locale Refresh

**Status:** Accepted  
**Date:** 2026-07-21  
**Decisions:** D29.1–D29.8  
**Extends:** ADR-022 (Localized Runtime Delivery and Locale Switching), ADR-002 (Runtime Architecture), ADR-006 (Runtime Execution), ADR-010 (UI and Presenter), ADR-014 (Product Structure and Presentation), ADR-019 (Presentation Growth Constraints)  
**Amends:** ADR-022 D28.10, D28.12; ADR-022 D28.18 presenter-gate note for this narrow case  
**Clarifying amendments completed in:** ADR-006, ADR-010, ADR-022, `04-runtime-and-integration.md`, `addons/dialogue_framework/docs/game_presenter.md`, `addons/dialogue_framework/README.md`

---

## Context

ADR-022 D28.10 / D28.12 require that on active locale change during `AwaitingChoice`, Runtime reconstruct and re-present the visible **CHOICES** step with updated localized option labels, without changing traversal semantics.

Presentation product behavior (and existing Presentation tests) keeps the **prompting LINE** co-visible while choices are shown: the dialogue line box continues to display the last LINE body after Runtime has advanced to `AwaitingChoice` and `_current_step` is a CHOICES step.

Under D28.10 as originally stated, locale refresh updated only `_current_step` (CHOICES). The co-visible LINE therefore remained in the previous locale, producing a mixed-language dialogue UI that players reasonably treat as broken.

`IDialoguePresenter` already exposes a default no-op `refresh_line_text(step)` intended for in-place line updates without rebuilding choice UI. This ADR authorizes that contract formally and binds Runtime to use it during `AwaitingChoice` locale refresh when a prompting LINE is known.

---

## Problem Statement

Locale refresh must update **all Runtime-authored dialogue text still shown** for the active conversation during `AwaitingChoice`, not only the CHOICES step DTO, while preserving ownership (Runtime localizes; Presentation displays), phase/traversal invariants, and avoiding a CHOICES DTO schema expansion.

---

## Scope

This ADR defines:

- Co-visible authored surface for **locale refresh only** during `AwaitingChoice`.
- Delivery mechanism: `refresh_line_text` for the prompting LINE; `present(CHOICES)` for options.
- Soft-state prompting LINE identity (not a save coordinate).
- Verification expectations and ADR-019 D25.2 authorization for this narrow change.

---

## Explicit Non-Scope

This ADR must **not**:

- Add prompt fields to the CHOICES `ConversationStep` DTO.
- Allow Presentation catalog lookup for line body or choice labels.
- Change traversal, option filtering, option order/targets, or `AwaitingChoice` phase.
- Redefine locale behavior for `WAIT`, `ExecutingCommand`, `Idle`, or `Ended`.
- Change when Presentation shows or hides the prompting line (layout policy remains Presentation).
- Redesign typewriter restart policy beyond: `refresh_line_text` must not restart choice UI or change phase.

---

## Decision D29.1 — Co-Visible Authored Surface (Locale Refresh Only)

### Decision

During **`AwaitingChoice` locale refresh**, the authored dialogue surfaces Runtime must update are:

1. Localized labels for every **visible** CHOICES option (ADR-022 D28.12), and  
2. The **co-visible prompting LINE** body (and language-neutral `speaker_id` for Presentation speaker resolution), when a prompting LINE identity is known (D29.3).

This does **not** redefine “active step” for advance/choose/command semantics. `_current_step` remains the CHOICES step. Co-visibility applies only to locale refresh obligations.

### Rationale

Player expectation is that all dialogue HUD text for the current conversation switches together. Phase-owned `_current_step` alone under-specified that expectation for the established prompt+choices presentation convention.

---

## Decision D29.2 — Delivery Mechanism

### Decision

1. Rebuild a localized **LINE** `ConversationStep` for the prompting `line_id` using the same LINE rebuild path as `PresentingLine` / `AwaitingInput` refresh (including interpolation re-resolution per ADR-022 D28.15).
2. Deliver that LINE via **`IDialoguePresenter.refresh_line_text(step)`** — in-place speaker/line update; **must not** change `ConversationPhase`, **must not** replace `_current_step` with the LINE, **must not** require rebuilding the choices panel.
3. Rebuild and deliver the **CHOICES** step via existing `present(step)` (ADR-022 D28.12).

`present(LINE)` **must not** be used for the co-visible prompt during `AwaitingChoice` locale refresh (avoids typewriter/entry restart and phase confusion).

### Rationale

Uses the existing presenter seam; keeps CHOICES as the phase’s primary `present` delivery; avoids DTO expansion.

---

## Decision D29.3 — Prompting LINE Soft State

### Decision

Runtime maintains conversation-scoped soft state: the **last delivered LINE** `line_id` for the active conversation (`_prompting_line_id` or equivalent).

| Rule | Requirement |
|------|-------------|
| Set | When Runtime delivers a LINE step (`start` / advance / resume LINE delivery). |
| Retain | Across subsequent CHOICES delivery and `AwaitingChoice` locale refresh. |
| Clear | With other conversation refs on end / cancel / cleanup to Idle. |
| Persist | **Not** part of `DialogueSnapshot` (ADR-022 D28.13 unchanged). |

If prompting LINE id is empty at refresh time, Runtime performs **CHOICES-only** refresh (no error). Presenters that no-op `refresh_line_text` remain valid.

### Rationale

Soft state is deterministic for normal LINE→CHOICES flows and avoids fragile graph inference.

---

## Decision D29.4 — Amendment to ADR-022 D28.10 / D28.12

### Decision

ADR-022 D28.10 `AwaitingChoice` guarantee is amended to:

> Locale refresh: reconstruct and re-deliver the visible localized CHOICES step per D28.12, **and** update the co-visible prompting LINE via `refresh_line_text` when prompting LINE identity is known (ADR-023 D29.1–D29.3); cursor and phase unchanged.

ADR-022 D28.12 is amended to include step (after CHOICES reconstruct obligations):

> When prompting LINE soft state is non-empty, rebuild and `refresh_line_text` that LINE before or after CHOICES re-present, without changing `_current_step` away from CHOICES or altering choice structural fields.

Normative detail lives in this ADR; ADR-022 retains a cross-reference.

---

## Decision D29.5 — `IDialoguePresenter.refresh_line_text`

### Decision

`IDialoguePresenter.refresh_line_text(step: ConversationStep) -> void` is part of the presenter contract for this case:

- **Default:** no-op (backward compatible for custom presenters).
- **Reference Presentation:** updates speaker display (via `tr(speaker_id, "speakers")`) and line body in place without clearing/rebuilding choices.
- Runtime **must** call it during `AwaitingChoice` locale refresh when a prompting LINE step was successfully rebuilt.

This is a **narrow** presenter-contract authorization under ADR-019 D25.2. It does not authorize unrelated presenter API growth.

### Rationale

Formalizes an existing code seam; default no-op preserves Open/Closed for custom presenters.

---

## Decision D29.6 — ADR-019 D25.2 Change Gate

### Decision

Acceptance of this ADR **authorizes implementation** of:

| Gated / related contract | Authorization |
|--------------------------|---------------|
| ADR-022 D28.10 / D28.12 semantics (co-visible LINE) | This ADR |
| `IDialoguePresenter.refresh_line_text` as documented contract | This ADR (narrow) |
| ConversationController soft state + locale-refresh wiring | This ADR |

**Not authorized:** CHOICES DTO prompt fields; Presentation catalog lookup; unrelated `IDialoguePresenter` methods.

---

## Decision D29.7 — Architectural Verification Expectations

### Decision

The following must be verifiable:

| Property | Layer |
|----------|-------|
| `AwaitingChoice` locale refresh updates CHOICES labels | Runtime (existing) |
| With known prompting LINE, locale refresh updates LINE body via `refresh_line_text` | Runtime / Presentation integration |
| Phase, option order, `target_line_id`, indices unchanged | Runtime |
| `_current_step` remains CHOICES after refresh | Runtime |
| Empty prompting soft state → CHOICES-only refresh, no error | Runtime |
| Default no-op `refresh_line_text` does not break refresh | Presenter contract |

---

## Decision D29.8 — Explicit Non-Regression

### Decision

`PresentingLine` / `AwaitingInput` locale refresh continue to use `present(LINE)` only (ADR-022 D28.10). This ADR does not change those phases.

---

## Alternatives Considered

| Alternative | Why rejected |
|-------------|--------------|
| Add prompt text to CHOICES DTO | ADR-019 D25.2 heavier; YAGNI given `refresh_line_text`. |
| Presentation re-translates co-visible line | Violates ADR-022 D28.6. |
| Clear/hide line on locale switch | Avoids mixed language but worsens UX. |
| `present(LINE)` then `present(CHOICES)` | Risks typewriter restart and phase confusion. |
| Redefine active surface for all phases | Overbroad; fights phase model. |

---

## Consequences

- ADR-022 D28.10 / D28.12 clarifying amendments required.
- ADR-010 presenter contract docs must mention `refresh_line_text`.
- Implementation: ConversationController soft state + wiring; tests for co-visible refresh.
- Custom presenters may keep default no-op if they do not keep a co-visible line.

---

## Related Documents

- [022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
- [010-ui-and-presenter.md](010-ui-and-presenter.md)
- [006-runtime-execution.md](006-runtime-execution.md)
- [019-presentation-growth-constraints.md](019-presentation-growth-constraints.md)
