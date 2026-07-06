# ADR 006: Runtime Execution

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D6.1–D6.10

## Context

Runner traversal must skip structural nodes, yield presentation steps, and coordinate with controller phases for commands, waits, and choices.

## Decision

1. **Recursive skip-until-yield** traversal (D6.1).
2. **Commands yield COMMAND step** except `@wait` → WAIT (D6.2, D6.5).
3. **Single CHOICES step** per choice group (D6.3).
4. **Sibling chain** for false condition branches (D6.4).
5. **WAIT:** controller awaits duration, auto `advance()`, no presenter (D6.5).
6. **Explicit `=> END`** termination (D6.6).
7. **Hard `cancel()`** — no await/abort of in-flight commands (D6.7).
8. **COMMAND sequence:** ExecutingCommand → optional dismiss → await handler → `command_executed` → auto advance (D6.8).
9. **CHOICES:** advance → AwaitingChoice → step_ready → present (D6.9).
10. **Zero visible choices:** assert + `conversation_ended(compiled)` (D6.10).

## Consequences

- `@wait` bypasses presenter entirely.
- Choice UI must call `controller.choose()`, not presenter callbacks.
- Async commands can complete after cancel (ignored).

## References

- [04-runtime-and-integration.md](../04-runtime-and-integration.md)
- [01-architecture-overview.md](../01-architecture-overview.md)
