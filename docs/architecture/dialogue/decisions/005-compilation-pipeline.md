# ADR 005: Compilation Pipeline

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D5.1–D5.11

## Context

Compile-at-import catches errors early. DM uses multi-stage compilation; manifests need ProjectSettings discovery like Dialogic variables and DM settings.

## Decision

1. **EditorImportPlugin** on `.dlg` (D5.1).
2. **Version fields** on resource: `format_version`, `compiler_version` (D5.2).
3. **Fail import on errors** (D5.3).
4. **3-stage compile:** lines → indent tree → flat graph + tokenize (D5.4).
5. **No cross-file import** in v1 (D5.5).
6. **Tokenize conditions/commands** at compile (D5.6).
7. **`compile_string()`** dev/test only (D5.7).
8. **Choice-block grouping** — consecutive CHOICE lines at same indent after LINE (or block start) compile to one group; shared next_id_after; runtime yields single CHOICES at first CHOICE id (D5.8).
9. **Goto validation** — `=> title` must match `titles` map; store `resolved_target_line_id` (D5.9).
10. **ProjectSettings** paths for `FlagManifest` and `CommandManifest` (D5.10).
11. **Condition-block exit wiring** — after linear `_wire_next_ids`, each if/elif/else block sets `next_id_after` on all condition headers to the first line after the block; each branch body's **last** line `next_id` is set to the same continuation (D5.11). Requires `COMPILER_VERSION` 2+.

## Consequences

- Invalid dialogue never becomes a `.tres`.
- Game must configure manifest paths before strict validation applies.
- Import plugin must load manifests before each compile.
- Re-import `.dlg` files after upgrading to a build with `COMPILER_VERSION` 2 so condition exit wiring is present in `.tres` outputs.

## Localization amendment (ADR-021)

- **Identity generation:** The compiler must generate translation identity for every in-scope localized authored text surface (LINE body and choice labels); "missing translation identity" is not a valid state for newly compiled resources (ADR-021 D27.10). When no author-provided override exists, the compiler generates a deterministic fallback using the existing D13.2 principle `{source_path}::{source_line_number}` applied to the surface's authored source location (ADR-021 D27.8).
- **Identity validation:** Empty translation identity is a compile error in all validation tiers. Duplicate translation identity within one compiled dialogue resource is a **warning** on local editor import and an **error** under `--strict` CI, consistent with tiered validation (D15.3, ADR-021 D27.10, D27.7). Character-set, length, and normalization rules beyond non-empty are deferred to a future ADR.
- **Compile processor immutability:** The optional compile processor (D17.3) must not modify or replace translation identity for any localized text surface (ADR-021 D27.13).
- **Compatibility:** LINE identity remains backward compatible; CHOICE identity is forward-only, with reimport of `.dlg` as the remediation path. Schema-capability detection uses `format_version` or an equivalent version signal (ADR-021 D27.11); numeric values and loader behavior are ADR-019 D25.2 implementation concerns.

## References

- [03-compilation-and-data.md](../03-compilation-and-data.md)
- [decisions/020-localization-architecture.md](020-localization-architecture.md)
- [decisions/021-localized-authoring-compiled-identity.md](021-localized-authoring-compiled-identity.md)
