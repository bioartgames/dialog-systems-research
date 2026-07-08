# ADR 017: Presentation Accessibility

**Status:** Accepted  
**Date:** 2026-07-08  
**Decisions:** D23.1–D23.5  
**Derives from:** [07-presentation-product-spec.md](../07-presentation-product-spec.md) v1  
**Extends:** ADR-014 D20.3 (accessibility behavior)

## Context

ADR-014 assigned Presentation ownership of accessibility behavior for dialogue UI. The Presentation Product Specification v1 defines how accessibility is split across Policy (behavior) and Theme (visual variants), and clarifies that Ui React may enhance but not replace Presentation's dialogue accessibility responsibilities.

## Decision

1. **Presentation owns dialogue accessibility (D23.1)** — Dialogue-specific accessibility behavior is Presentation responsibility, not Ui React or Game implementation responsibility. This includes behavior required for the native-only reference layout without Ui React.

2. **Policy owns motion and behavioral a11y (D23.2)** — Policy owns reduced-motion behavior (including skipping typewriter), tag timing adjustments under accessibility conditions, and optional selection of an alternate Theme when accessibility settings require it.

3. **Theme owns visual a11y variants (D23.3)** — Theme owns high-contrast and large-text visual variants, choice focus visibility styling, and related visual tokens. Accessibility visual variants are duplicate Theme resources or Theme variants assignable from game settings.

4. **Scope limits (D23.4)** — v1 product scope includes Policy reduced-motion support, Theme accessibility variants, and choice keyboard navigation via Presentation Input and default handling. Screen reader and narration pipeline integration is **out of v1 scope** and requires a future ADR.

   Ui React may optionally enhance control-level focus or animation where attached to layout regions. Ui React does not own dialogue accessibility rules.

5. **Game applies settings (D23.5)** — Game selects appropriate Policy and Theme resources from player settings. This is orchestration, not presentation technology authorship.

## Consequences

- Reference Presentation content ships accessibility-capable Policy and Theme defaults.
- Native baseline layouts must honor reduced-motion Policy without Ui React.
- Expanded accessibility (screen readers, narration) requires explicit future ADR before product expansion.

## References

- [07-presentation-product-spec.md](../07-presentation-product-spec.md)
- [decisions/015-presentation-product-concepts.md](015-presentation-product-concepts.md)
- [decisions/016-presentation-input-ownership.md](016-presentation-input-ownership.md)
- [decisions/014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
