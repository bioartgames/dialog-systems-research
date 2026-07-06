# ADR 004: Authoring Format

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D4.1–D4.9

## Context

Authors need familiar syntax without colliding with reference plugins in the same repo. DM-inspired subset fits action-RPG dialogue density.

## Decision

1. **`.dlg` extension** (D4.1).
2. **DM-inspired subset** trimmed for RPG (D4.2).
3. **`Speaker: text`** lines; speaker via `tr()` only (D4.3).
4. **Choice lines** with optional `if` condition and `=> target` (D4.4).
5. **Pythonic if/elif/else** with indentation (D4.5).
6. **`@command args`** prefix for side effects (D4.6).
7. **`=> title` / `=> END`** gotos (D4.7).
8. **`#tag` / `#key=value`** metadata; no `#portrait` in v1 (D4.8, D11.4).
9. **One `.dlg` per NPC/conversation** (D4.9).

## Consequences

- Authors can reference DM documentation for general familiarity.
- Portrait and cross-file features require future ADRs.
- Tag set is intentionally minimal for 3D subtitle presentation.

## References

- [02-authoring-format.md](../02-authoring-format.md)
