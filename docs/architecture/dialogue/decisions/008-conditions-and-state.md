# ADR 008: Conditions and State

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D8.1–D8.7, D9.1–D9.6

## Context

Neither reference plugin enforces a fixed condition facade. Need testable evaluator, compile-time flag validation, and no duplicate state store.

## Decision

1. **ConditionEvaluator** — dedicated testable class (D8.1).
2. **GameContext facade only** in conditions — no arbitrary calls (D8.2).
3. **Inline choice conditions**; hidden if false (D8.3).
4. **No inline text conditionals** in v1 (D8.4).
5. **`{name}` interpolation** via `get_display_value` at step build (D8.5).
6. **Author DSL:** `flag()`, `has_item()`, `get_quest_state()` — not `get_flag()` (D8.6).
7. **Token grammar (D8.7):** compile produces token arrays; runtime interprets literals (bool, int, float, string); operators `==`, `!=`, `<`, `<=`, `>`, `>=`, `and`, `or`, `not`; calls `flag(name)`, `has_item(id)`, `get_quest_state(id)` only; `{brace}` keys validated against FlagManifest, resolved via `GameContext.get_display_value` at step build.
8. **No dialogue var store** — context only (D9.1).
9. **GameContext injected per start()** (D9.2).
10. **Writes via context + `@set_flag`** (D9.3).
11. **FlagManifest** validates `flag()` refs and `{brace}` keys only (D9.4).
12. **`get_display_value`** for braces (D9.5).

## Consequences

- Typos in flag names caught at compile (when manifest configured).
- `has_item` / `get_quest_state` IDs not manifest-checked in v1.
- Authors must use `flag("x")` syntax, not `get_flag("x")`.

## Localization amendment (ADR-022 D28.15)

`{name}` interpolation values remain **Delegated** to the game and are not part of translation resolution (ADR-020 D26.8-interpolation). When Runtime performs a LINE locale refresh (D13.4), it re-resolves both the localized line body and the delegated interpolation placeholder values (via `GameContext.get_display_value`) at reconstruction time, so locale-sensitive game values can update (ADR-022 D28.15). This does not change the D8.5 delegation model.

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [04-runtime-and-integration.md](../04-runtime-and-integration.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
