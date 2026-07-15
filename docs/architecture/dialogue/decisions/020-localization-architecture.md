# ADR 020: Localization Architecture

**Status:** Accepted  
**Date:** 2026-07-11  
**Decisions:** D26.1-D26.18  
**Contract ADRs:** ADR-021 (Localized Authoring and Compiled Identity) and ADR-022 (Localized Runtime Delivery and Locale Switching) define the compile-time and runtime contracts for this subsystem model.  
**Supersedes:** ADR-011 D13.1-D13.4 as the complete localization model (D13.3 speaker behavior is retained by D26.16).  
**Clarifying amendments completed in:** ADR-003, ADR-004, 

## Context

Localization in authored dialogues must support both line-level body text and choice labels. The runtime presentation may own some surfaces (e.g. speaker display names) while compiled identity-based translation is used for authored text bodies and choice labels. This ADR defines ownership, compile-time identity generation, and runtime delivery patterns for dialogue localization.

## Decisions

D26.1 Localized surfaces: The compiler will assign a deterministic translation identity for all authored text surfaces that require translation at runtime. Localized surfaces include LINE body text and CHOICE labels. Speaker display names are explicitly excluded and remain a presentation-layer responsibility.

D26.2 Identity model: The compiled translation identity is the single source used by runtime translation lookups (TranslationServer or equivalent). Author-provided IDs (via authoring override) are respected; otherwise the compiler generates stable fallbacks based on source path and line number.

D26.3 Ownership: The runtime is responsible for resolving compiled translation identities into localized text. Presentation components may perform additional formatting, trimming, or visual replacement.

D26.4 Choice labels: CHOICE labels are a localized authored text surface; the compiler must emit translation identity for CHOICE nodes in the compiled resource.

D26.5 Validation: The compilation pipeline must validate presence of translation identities for localized surfaces and surface-level uniqueness to prevent accidental duplicates. Strict compile mode treats duplicates as errors.

D26.6 Format versioning: Changes to compiled translation identity storage or runtime behavior require a format version bump and documented migration notes.

(Additional decisions omitted for brevity — see ADR-021 for compiled identity rules.)
