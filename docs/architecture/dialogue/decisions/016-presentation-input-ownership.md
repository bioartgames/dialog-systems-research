# ADR 016: Presentation Input Ownership

**Status:** Accepted  
**Date:** 2026-07-08  
**Decisions:** D22.1–D22.3  
**Derives from:** [07-presentation-product-spec.md](../07-presentation-product-spec.md) v1  
**Amends:** ADR-014 D20.6 (clarification), ADR-010 integration guidance (clarification)

## Context

ADR-014 assigned games responsibility for orchestration and input routing. The Presentation Product Specification v1 clarifies that reusable dialogue UX input (skip typewriter, advance line, choice navigation and confirmation) is Presentation technology, not game technology. Games retain authority over when conversations run, gameplay pause, and input override when UI layers compete.

## Decision

1. **Presentation owns dialogue UX input by default (D22.1)** — For the common case, Presentation provides default handling for:
   - Skip typewriter during line presentation
   - Advance after line reveal (`ConversationController.advance()`)
   - Navigate and confirm choices (`ConversationController.choose()`)

   Game does **not** reimplement this logic when using reference layouts.

2. **Input is a composable concept (D22.2)** — Dialogue UX input mapping is configurable through the Presentation **Input** concept (resource assignable in reference layouts). Reference layouts include default input handling that consumes the Input resource.

3. **Game orchestration and override (D22.3)** — Game owns:
   - When conversations start and stop
   - Pausing or restricting player control during conversations
   - Optionally overriding or disabling default presentation input when other UI systems compete for the same player actions

   Applying player settings by selecting Policy or Theme resources is game orchestration, not presentation implementation.

## Consequences

- Integration guides describe default presentation input as zero-script for reference layouts.
- Games needing custom input arbitration disable or replace default presentation input rather than duplicating skip/navigate logic in orchestrators.
- `game_presenter.md` and similar docs distinguish **presentation input** from **game orchestration input**.

## References

- [07-presentation-product-spec.md](../07-presentation-product-spec.md)
- [decisions/015-presentation-product-concepts.md](015-presentation-product-concepts.md)
- [decisions/014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
- [decisions/009-game-integration.md](009-game-integration.md)
