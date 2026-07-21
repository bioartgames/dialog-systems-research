# ADR 019: Presentation Growth Constraints

**Status:** Accepted  
**Date:** 2026-07-08  
**Decisions:** D25.1–D25.3  
**Derives from:** [07-presentation-product-spec.md](../07-presentation-product-spec.md) v1  
**Extends:** ADR-001 (YAGNI), ADR-010 (D11.4), ADR-014

## Context

The Presentation Product Specification v1 defines how Presentation evolves over time without expanding Runtime responsibilities. This ADR normatively records the asset-based growth model and defers features that require Runtime or `ConversationStep` changes.

## Decision

1. **Asset-based growth (D25.1)** — Presentation evolves by adding assets:
   - New layout scenes and variants for dialogue styles (VN, balloon, RPG box, etc.)
   - New Theme and Policy resources
   - New Input resources
   - Richer motion configuration within layouts

   Runtime responsibilities do **not** expand to absorb presentation features.

2. **Runtime changes require ADR (D25.2)** — Changes to `ConversationStep`, `CompiledLine` / `CompiledDialogue` schema, `ConversationPhase` state machine, or `IDialoguePresenter` contract require an explicit future ADR before implementation. Examples: portrait fields, new step kinds for presentation, presenter contract callbacks.

3. **v1 product surface (D25.3)** — Aligned with ADR-001 YAGNI and ADR-010 D11.4:
   - Subtitle-style layouts only
   - Minimum one native-only reference layout; one or two layout variants
   - Core Theme, Policy (including overflow and reduced motion), and Input defaults
   - No portraits; no `#portrait` tag; no portrait field on `ConversationStep`

4. **Portrait deferral (D25.4)** — Portrait display requires a future ADR covering tag syntax, layout regions, Theme styling, and any `ConversationStep` amendments before product implementation.

5. **Screen reader deferral (D25.5)** — Screen reader and narration pipeline integration is out of v1 product scope (ADR-017 D23.4).

## Consequences

- New dialogue styles are Presentation layout assets, not Runtime features.
- Product roadmap items that touch Runtime are flagged for ADR before implementation.
- v1 reference content scope is documented separately and tracked against this ADR.

## Localization amendment (ADR-021 D27.18, ADR-022 D28.18)

The localization contract ADRs satisfy the D25.2 gate for localization-affecting contracts. The following D25.2-gated contracts are now **architecturally authorized** for implementation design (implementation still requires explicit change-gate authorization):

| Gated contract | Authorized by |
|----------------|---------------|
| `CompiledLine` schema (choice-label translation identity binding) | ADR-021 D27.18 |
| `CompiledDialogue` schema / version signaling | ADR-021 D27.18 |
| `ConversationStep` delivery semantics (localized LINE body + choice labels) | ADR-022 D28.18 |
| `ConversationPhase` behavior (`AwaitingChoice` locale refresh; `Idle`/`ExecutingCommand`/`Ended` guarantees) | ADR-022 D28.18 |

`IDialoguePresenter` is **not** implicated for v1 localization: the contract is satisfied by localized strings on the existing `present(step)` delivery (ADR-022 D28.18). No other gated contract is authorized by these ADRs.

## Product structure amendment (ADR-024)

Adding optional `integration/` does **not** expand D25.2-gated Runtime contracts. Kit surfaces that only call existing public Runtime APIs are authorized by [ADR-024](024-optional-game-integration-kit.md) D30.9. Changes to `ConversationStep`, compiled schemas, phases, or `IDialoguePresenter` still require an explicit future ADR.

## References

- [07-presentation-product-spec.md](../07-presentation-product-spec.md)
- [decisions/015-presentation-product-concepts.md](015-presentation-product-concepts.md)
- [decisions/017-presentation-accessibility.md](017-presentation-accessibility.md)
- [decisions/018-presentation-consumer-customization.md](018-presentation-consumer-customization.md)
- [00-project-goals.md](../00-project-goals.md)
- [decisions/021-localized-authoring-compiled-identity.md](021-localized-authoring-compiled-identity.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
- [decisions/024-optional-game-integration-kit.md](024-optional-game-integration-kit.md)
