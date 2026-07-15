class_name DialogueFrameworkVersions


## CompiledDialogue schema version (D3.1, D5.2).
## v1: LINE `translation_key` only; CHOICE nodes lack choice-label translation identity.
## v2: CHOICE nodes include `translation_key` (ADR-021 D27.11).
const FORMAT_VERSION: int = 2

## Minimum `format_version` for complete CHOICE translation identity (ADR-021 D27.11).
const FORMAT_VERSION_CHOICE_TRANSLATION_IDENTITY: int = 2

## Dialogue compiler version written to compiled resources (D5.2).
const COMPILER_VERSION: int = 2
