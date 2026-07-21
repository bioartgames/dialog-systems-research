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

## Localization amendment (ADR-021, ADR-022)

- **Translation identity (ADR-021 D27.2):** Every localized authored **text** surface carries translation identity. On `LINE`, `translation_key` is the existing v1 storage binding for translation identity (unchanged by this amendment). Choice labels are classified Localized (ADR-020 D26.4) and gain an equivalent translation-identity binding upon implementation; the CHOICE field name is ADR-019 D25.2-gated and not defined here.
- **Traversal identity vs translation identity (ADR-021 D27.3):** The graph line `id` (traversal identity, used for branching and save/resume coordinates) and translation identity are distinct architectural identities; they may coincide in value but are not required to. Save/resume coordinates use **traversal identity only** (ADR-011 D12.2).
- **Compiled preservation obligation (ADR-021 D27.9):** For every localized text surface, compiled data preserves both the translation identity (language-neutral) and the authored source text in the **authoring language**. Preserved source text is authoring-language source, not localized runtime output.
- **`ConversationStep` localized delivery (ADR-022 D28.5):** Runtime delivers localized display text for `LINE` body and each visible `CHOICES` option label, while `line_id`, option `target_line_id`, indices, and `speaker_id` remain language-neutral. Concrete DTO field names and layout remain ADR-019 D25.2-gated and are not defined here.

## References

- [03-compilation-and-data.md](../03-compilation-and-data.md)
- [decisions/020-localization-architecture.md](020-localization-architecture.md)
- [decisions/021-localized-authoring-compiled-identity.md](021-localized-authoring-compiled-identity.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
