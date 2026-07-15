# ADR 021: Localized Authoring and Compiled Identity Contract

**Status:** Accepted  
**Date:** 2026-07-11  
**Decisions:** D27.1–D27.18  
**Extends:** ADR-020 (Localization Architecture), ADR-003 (Data Model), ADR-004 (Authoring Format), ADR-005 (Compilation Pipeline), ADR-012 (Validation, Tooling, and Testing)  
**Prerequisite for:** ADR-022 — Localized Runtime Delivery and Locale Switching Contract (**Accepted**)  

## Context

Compiled translation identity provides a stable, language-neutral reference for runtime localization. This ADR specifies how authoring surfaces obtain translation identities, how the compiler generates fallbacks, how validation enforces uniqueness/non-empty identities, and how runtime resolves localized text.

## Decisions

D27.1 Surfaces: LINE body text and CHOICE labels are considered localized authoring surfaces and shall carry compiled translation identities.

D27.2 Author overrides: If an author supplies an explicit translation id using the authoring override syntax, the compiler must use it as the translation identity for that surface.

D27.3 Deterministic fallback: If no author-provided id exists, the compiler must generate a deterministic fallback identity using the pattern {source_path}::{line_number}.

D27.4 Compiler generation: The compiler must call the LineIdGenerator.resolve_translation_key(...) for both LINE and CHOICE surfaces when emitting compiled resources. This method encapsulates author overrides and deterministic fallback generation.

D27.5 Storage: Compiled CHOICE nodes must store translation_key using the same KEY_TRANSLATION_KEY used for LINE nodes.

D27.6 Validation: The compilation pipeline shall run TranslationIdentityValidator which checks: non-empty identities on localized surfaces, duplicate identity detection (warnings in non-strict, errors in strict), and reports if compile processors mutate identities.

D27.7 Runtime use: The runtime shall look up choice labels using the compiled translation_key and present localized text via the same translation pipeline used for LINE body text.

D27.8 Format gating: The CHOICE translation identity behavior must be gated by a format-version constant. Implementations must set DialogueFrameworkVersions.FORMAT_VERSION and define DialogueFrameworkVersions.FORMAT_VERSION_CHOICE_TRANSLATION_IDENTITY to the appropriate value.

D27.9 Migration: When format_version is increased, the importer and resource format must be able to read older format versions and upgrade or warn as appropriate.

(Additional clauses omitted for brevity.)
