# ADR 002: Runtime Architecture

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D2.1–D2.6

## Context

Need a clear public API, deterministic conversation phases, and separation between traversal and presentation. Dialogue Manager couples UI to advance; Dialogic uses subsystem state machines.

## Decision

1. **ConversationController** exposes full public API with typed methods and signals (D2.1). `start()` returns `false` if conversation already active (D2.4).
2. **DialogueRunner** is a separate pure class with `load`, `init_from_title`, `set_cursor`, `next_step`, `peek_step_kind` (D2.2).
3. **ConversationPhase** enum with explicit transition table: `Idle`, `PresentingLine`, `AwaitingInput`, `AwaitingChoice`, `ExecutingCommand`, `Ended` (D2.3).
4. **Hybrid async** — After runner yields, controller emits `step_ready(step)` then calls `presenter.present(step)` (D2.5). The presenter is an `IDialoguePresenter` implementation supplied by the game (typically from the Presentation subsystem or a custom class).
5. Package at **`addons/dialogue_framework/`** (D2.6). Runtime code lives under `runtime/`; see ADR-014 for Presentation subsystem.

## Consequences

- Game integrates via controller autoload, not runner directly.
- **LINE** progression: presenter calls `notify_presentation_finished()`; then game or presenter calls `advance()`.
- **CHOICES** progression: `ConversationController.choose()`.
- **WAIT:** controller auto-`advance()` after duration (no presenter).
- **COMMAND:** controller auto-`advance()` after handler completes.
- Single active conversation only in v1.
- Runtime never imports Presentation (ADR-014).

## Localization amendment (ADR-022 D28.10)

Every `ConversationPhase` (D2.3) has a defined locale-switch guarantee under ADR-022 D28.10. On active locale change during an in-progress conversation, Runtime honors those per-phase guarantees without altering traversal semantics. In addition to the existing `PresentingLine` / `AwaitingInput` LINE refresh (ADR-011 D13.4), `AwaitingChoice` performs a locale refresh of the visible CHOICES step (ADR-022 D28.10, D28.12); `Idle`, `ExecutingCommand`, and `Ended` have the guarantees stated in ADR-022 D28.10. This extends phase behavior and is ADR-019 D25.2-gated for implementation.

## References

- [01-architecture-overview.md](../01-architecture-overview.md)
- [04-runtime-and-integration.md](../04-runtime-and-integration.md)
- [06-product-structure.md](../06-product-structure.md)
- [decisions/014-product-structure-and-presentation.md](014-product-structure-and-presentation.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
