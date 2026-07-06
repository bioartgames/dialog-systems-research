# ADR 013: Future Editor Support

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D19.1–D19.4

## Context

v1 is text-first. Visual editors add complexity and are not required for action-RPG dialogue density.

## Decision

1. **Visual editor deferred indefinitely** (D19.1).
2. **`.dlg` text always canonical** — editor would be a view, not source of truth (D19.2).
3. **No editor metadata on CompiledLine in v1** (D19.3).
4. **In-editor playtest deferred** — use game run + automated tests (D19.4).

## Consequences

- v1 workflow: external editor → save `.dlg` → Godot reimport.
- Any future editor must round-trip to `.dlg` text.
- No `CompiledLine` editor-only fields to migrate later.

## References

- [05-open-questions.md](../05-open-questions.md)
- [decisions/012-validation-tooling-testing.md](012-validation-tooling-testing.md)
