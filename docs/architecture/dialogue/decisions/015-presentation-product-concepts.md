# ADR 015: Presentation Product Concepts

**Status:** Accepted  
**Date:** 2026-07-08  
**Decisions:** D21.1–D21.6  
**Derives from:** [07-presentation-product-spec.md](../07-presentation-product-spec.md) v1  
**Extends:** ADR-014 (D20.1–D20.6)

## Context

ADR-014 established Runtime and Presentation as sibling subsystems and assigned Presentation ownership of dialogue UI technology. The Presentation Product Specification v1 defines how consumers adopt and customize Presentation through editor-first concepts without prescribing implementation.

This ADR normatively records the four editor-facing product concepts, the Theme/Policy split, the layout product model, and mixed Ui React composition.

## Decision

1. **Four composable concepts (D21.1)** — Presentation exposes four editor-facing concepts consumers mix independently:
   - **Layout** — structure and screen composition (dialogue HUD scenes).
   - **Theme** — visual identity only.
   - **Policy** — behavior and timing only.
   - **Input** — dialogue UX input mapping.

2. **Theme and Policy are distinct (D21.2)** — Theme controls appearance. Policy controls behavior. Timing, typewriter, tag interpretation, and text overflow belong to Policy. Colors, fonts, spacing, and choice chrome belong to Theme. Structural dimensions are Theme; interaction semantics are Policy.

3. **Layout is the primary customization surface (D21.3)** — The consumer-facing product unit is a dialogue layout scene. Reference layouts include a pre-wired presenter implementing `IDialoguePresenter`. Consumers customize through Layout, Theme, Policy, and Input—not by rewriting presenter logic. Presenter subclassing is not a supported customization tier.

4. **Layout slot convention (D21.4)** — Every layout must provide identifiable regions for: speaker display, line text display, choice list, line visibility area, and choice visibility area. Consumers may rearrange visual composition but must preserve connectivity to these regions. Portrait regions are reserved for a future ADR; not required in v1.

5. **Native baseline (D21.5)** — At least one reference layout must function without Ui React installed (extends ADR-014 D20.5).

6. **Mixed Ui React composition (D21.6)** — Presentation is one product. Layouts may mix native Godot UI and Ui React controls per widget. Theme, Policy, and Input resources are shared regardless of control mix. Ui React never gains dialogue knowledge. Presentation never requires Ui React. Reference layout variants (e.g. choices-below, choices-right) are product content, not separate architectural paths.

## Consequences

- Presentation documentation and reference content organize around Layout, Theme, Policy, and Input.
- Implementation may introduce resource types and scene conventions that realize these concepts; this ADR does not prescribe them.
- ADR-010 presenter responsibilities (typewriter, tags, BBCode) are realized through Policy and Presentation internal coordination, not Runtime.

## References

- [07-presentation-product-spec.md](../07-presentation-product-spec.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
- [decisions/010-ui-and-presenter.md](010-ui-and-presenter.md)
