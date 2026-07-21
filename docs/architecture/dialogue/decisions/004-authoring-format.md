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

## Localization amendment (ADR-021)

- Dialogue line body text (D4.3) and choice labels (D4.4) are localized authored text surfaces and share one set of translation-identity principles (ADR-021 D27.5): optional author-provided override, deterministic compiler fallback when the override is absent, stability across recompile, within-resource uniqueness, and language-neutrality.
- Author-provided translation identity is **optional** for both dialogue lines and choice labels; production content SHOULD supply it (ADR-021 D27.4). The existing `[id:]` override on dialogue lines is unchanged.
- The **authoring expression** (syntax and source-line position) of a choice-label translation-identity override is defined in a future ADR-004 amendment, not here (ADR-021 D27.5). Speaker names remain resolved in Presentation via `tr(speaker_id, "speakers")` and receive no compiled translation identity (ADR-021 D27.12, ADR-020 D26.16).

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [decisions/020-localization-architecture.md](020-localization-architecture.md)
- [decisions/021-localized-authoring-compiled-identity.md](021-localized-authoring-compiled-identity.md)
