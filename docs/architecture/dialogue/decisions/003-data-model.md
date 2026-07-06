# ADR 003: Data Model

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D3.1–D3.9

## Context

Need Godot-native compiled resources with stable IDs for save/i18n, typed line kinds, and a presentation-neutral runtime DTO.

## Decision

1. **CompiledDialogue** `.tres` with `resource_uid`, `source_path`, `raw_text`, `format_version`, `compiler_version`, `titles`, `lines`, `first_title` (D3.1, D3.9).
2. **Lines dictionary** keyed by string line ID (D3.2).
3. **LineKind** enum: `TITLE`, `LINE`, `CONDITION`, `CHOICE`, `COMMAND`, `GOTO`, `END` (D3.3).
4. **CompiledLine** serialized as dict with shared + kind-specific fields (D3.8). `GOTO` stores `resolved_target_line_id`.
5. **ConversationStep** DTO kinds: `LINE`, `CHOICES`, `COMMAND`, `WAIT`, `END` with fields per D3.6. No portrait field.
6. Optional `[id:foo]` author IDs; compiler-generated `{source_path}::{line_number}` fallback (D3.7, D13.2).
7. **titles map** for NPC entry labels (D3.4).
8. **raw_text** + source path retained for debug (D3.5).

## Consequences

- Runtime never parses `.dlg` text.
- Structural nodes (`CONDITION`, `GOTO`, `TITLE`) skipped during yield.
- i18n keys stable across recompiles when `[id:]` used.

## References

- [03-compilation-and-data.md](../03-compilation-and-data.md)
