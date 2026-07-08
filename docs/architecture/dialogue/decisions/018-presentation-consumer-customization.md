# ADR 018: Presentation Consumer Customization

**Status:** Accepted  
**Date:** 2026-07-08  
**Decisions:** D24.1–D24.5  
**Derives from:** [07-presentation-product-spec.md](../07-presentation-product-spec.md) v1

## Context

The Presentation Product Specification v1 defines an editor-first adoption model: consumers customize dialogue primarily through layout scenes and resources, not scripts. This ADR normatively records the scripting boundary, Policy overflow behavior, and reference layout variant expectations.

## Decision

1. **Editor-first normal path (D24.1)** — The following customizations do **not** require scripting:
   - Duplicating or instancing reference layout scenes
   - Editing layout structure in the Godot scene editor (choice position, anchors, sizing)
   - Duplicating and assigning Theme, Policy, and Input resources
   - Mixing native Godot UI and Ui React controls within a layout
   - Wiring the layout's presenter into `ConversationController.start()`

2. **Scripting escape hatches (D24.2)** — Scripting is required only for:
   - Custom `IDialoguePresenter` implementations (world-space, 3D, non-standard widget systems)
   - Input override when default presentation input is insufficient
   - Game orchestration (conversation lifecycle, player pause, applying settings)
   - Layout topologies outside the slot convention (with custom presenter)

3. **Unsupported customization (D24.3)** — Subclassing or modifying reference presenter logic to change appearance, timing, choice position, or anchors is **not** a supported customization path.

4. **Policy overflow (D24.4)** — Policy owns text overflow behavior for line display. Normative modes: **grow**, **clamp**, and **scroll**. Layout sizing and Policy overflow mode combine to handle long dialogue lines without game scripts.

5. **Reference layout variants (D24.5)** — Multiple reference layouts for common patterns (e.g. choices-below, choices-right) are first-class product content. v1 may ship a subset aligned with ADR-001 YAGNI.

## Consequences

- Presentation reference content and guides target scene + resource workflows.
- Demo and game code should not embed reusable presentation UX logic for the normal path.
- Implementation of Theme, Policy, Input resource types follows this boundary but is not specified here.

## References

- [07-presentation-product-spec.md](../07-presentation-product-spec.md)
- [decisions/015-presentation-product-concepts.md](015-presentation-product-concepts.md)
- [decisions/016-presentation-input-ownership.md](016-presentation-input-ownership.md)
- [addons/dialogue_framework/presentation/reference-content-v1.md](../../../addons/dialogue_framework/presentation/reference-content-v1.md)
