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
4. **Hybrid async** — After runner yields, controller emits `step_ready(step)` then calls `presenter.present(step)` (D2.5).
5. Package at **`addons/dialogue_framework/`** (D2.6).

## Consequences

- Game integrates via controller autoload, not runner directly.
- **LINE** progression: presenter calls `notify_presentation_finished()`; then game or presenter calls `advance()`.
- **CHOICES** progression: `ConversationController.choose()`.
- **WAIT:** controller auto-`advance()` after duration (no presenter).
- **COMMAND:** controller auto-`advance()` after handler completes.
- Single active conversation only in v1.

## References

- [01-architecture-overview.md](../01-architecture-overview.md)
- [04-runtime-and-integration.md](../04-runtime-and-integration.md)
