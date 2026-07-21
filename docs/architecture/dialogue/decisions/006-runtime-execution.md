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
6. **Explicit `=> END`** termination: transition to Ended, dismiss active presenter if present, emit `conversation_ended(compiled)`, cleanup to Idle (D6.6).
7. **Hard `cancel()`** — no await/abort of in-flight commands (D6.7).
8. **COMMAND sequence:** ExecutingCommand → optional dismiss → await handler → `command_executed` → auto advance (D6.8).
9. **CHOICES:** advance → AwaitingChoice → step_ready → present (D6.9).
10. **Zero visible choices:** assert + `conversation_ended(compiled)` (D6.10).

## Consequences

- `@wait` bypasses presenter entirely.
- Choice UI must call `controller.choose()`, not presenter callbacks.
- Async commands can complete after cancel (ignored).
- Natural END, cancel, and invalid-cursor terminal paths all dismiss visible presentation UI.

## Localization amendment (ADR-022)

- **Localized CHOICES delivery (ADR-022 D28.4, D28.5):** When the runner yields a `CHOICES` step, Runtime delivers a localized label for each visible option resolved by that option's translation identity; option order, `target_line_id`, and indices remain language-neutral. LINE body text is delivered localized under the same contract.
- **`AwaitingChoice` locale refresh (ADR-022 D28.10, D28.12; ADR-023):** On active locale change while in `AwaitingChoice`, Runtime reconstructs and re-presents the visible CHOICES step with updated localized labels, preserving option order, targets, visible-option filtering result, the Runtime-owned selection index, cursor, and phase; and updates the co-visible prompting LINE via `refresh_line_text` when prompting LINE soft state is known (ADR-023); no player re-selection is required and traversal semantics do not change.
- **Missing / incomplete resources (ADR-022 D28.8, D28.9):** When translation resolution fails, or a pre-contract CHOICE resource lacks choice-label identity, Runtime falls back to the compiled authoring-language source text without parsing `.dlg`; incomplete choice resources are served degraded until reimport.
- **WAIT/COMMAND (ADR-022 D28.11):** `WAIT` and `COMMAND` steps display no authored localized text and require no locale refresh; the next visible step after completion uses the then-active locale.

## References

- [04-runtime-and-integration.md](../04-runtime-and-integration.md)
- [01-architecture-overview.md](../01-architecture-overview.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
