# Architecture Design Analysis: ADR A — Localized Authoring and Compiled Identity Contract

**Status:** Pre-ADR design analysis — not an ADR, not accepted architecture  
**Date:** 2026-07-11  
**Authority:** ADR-001 through ADR-020 (accepted); `localization-contract-adrs-outline.md` (planning)  
**Audience:** Architecture Review Board  
**Purpose:** Explore architectural alternatives for ADR A authorship. Recommendations below are **recommended for inclusion in ADR A**, not final decisions.

---

## Document Role

This analysis performs the architectural design work that should occur **before** ADR A is written. It does not create ADR text, does not modify existing ADRs, and does not design implementation.

---

## 1. Assumptions

1. **ADR-020 is accepted** and authoritative for localization philosophy, coverage, ownership principles, pipeline stages through compiled data, compatibility principles, and deferred questions D26.17/D26.18.
2. **ADR-019 D25.2 is authoritative**: any change to `CompiledLine` / `CompiledDialogue` schema requires an accepted ADR before implementation.
3. **ADR A is the first of two contract ADRs**; ADR B depends on ADR A but ADR A does not depend on ADR B.
4. **Existing LINE localization identity** (ADR-011 D13.2, ADR-003 D3.8) is in production use and must be treated as a compatibility anchor unless ADR A explicitly defines a superseding rule with migration/compatibility guarantees.
5. **Choice-label localization is a new architectural commitment** (ADR-020 D26.1b) that is not yet implemented; ADR A defines the identity contract that makes it implementable, not the implementation.
6. **Speaker display names** use `speaker_id` as identity and are Presentation-resolved per ADR-020 D26.16; ADR A operates in the compiled-identity layer for authored **text** only unless analysis proves otherwise.
7. **Compile-at-import** remains the production path (ADR-001 D1.3, ADR-005); runtime does not parse `.dlg` in production (ADR-003 consequence).
8. **This analysis uses only architecture documents** as evidence; implementation is not cited.

---

## 2. Constraints Inherited from ADR-020

| Constraint | Source | Implication for ADR A |
|------------|--------|------------------------|
| Localization is a property of all player-visible authored content (model B) | D26.3 | Choice labels must receive the same class of identity treatment as line body text unless a principled exception is documented. |
| Choice labels are **Localized** with Runtime-owned translation resolution | D26.4, D26.5 | Compiled data must carry identity sufficient for Runtime resolution; identity cannot be deferred to Presentation for choices. |
| Identity-mechanism ownership split | D26.5, D26.16 | ADR A covers compiled-identity text (LINE body, choices); speaker `speaker_id` is out of compiled-identity generation scope. |
| Every localized authored **text** object has stable translation identity | D26.6 | ADR A must define what "stable" means at compile boundary for each in-scope surface. |
| Author-provided or compiler-generated identity origins | D26.6 | ADR A must define rules for both origins per surface. |
| Existing LINE identities remain valid | D26.6 compatibility | ADR A must not silently invalidate D13.2 keys without compatibility contract. |
| Schema evolution for additional surfaces is D25.2-gated | D26.6, gated-work | ADR A acceptance authorizes contract; implementation still gated. |
| Compiler owns identity generation and validation | D26.5 | ADR A assigns compile-time guarantees, not runtime. |
| Compiled data preserves identity and source text for debug/fallback | D26.7 pipeline | ADR A must decide preservation obligations at data-contract level. |
| Compiled resources are language-neutral | D26.12 | Identity in compiled data is not a localized string. |
| D26.17 (choice interpolation) and D26.18 (locale refresh interpolation) are deferred | D26.17, D26.18 | ADR A should not silently resolve unless board scopes them here; analysis recommends deferral (see §6). |

---

## 3. Architectural Risks

| Risk | Description | Mitigation direction for ADR A |
|------|-------------|------------------------------|
| **LINE/choice identity divergence** | If choice identity uses a different model than LINE, authors and tooling face two mental models; translation pipelines fragment. | Prefer unified identity model with surface-agnostic rules where possible. |
| **line_id vs translation_key conflation** | Every `CompiledLine` already has `id` (line ID). Confusing line ID with translation identity could break save/resume (line_id in snapshots) or translation catalog stability. | ADR A must clarify the relationship between traversal identity and translation identity if they differ or coincide. |
| **Fallback identity fragility** | Source-line-based fallbacks break when authors edit layout; shipped games need stable author IDs. | ADR A should encode lifetime guarantees (D26.6) as contract requirements, not implementation. |
| **Compatibility cliff** | Adding required identity to CHOICE nodes may invalidate existing `.tres` without explicit compatibility rule. | ADR A must define detection/rejection/reimport expectation at architectural level. |
| **Scope creep into ADR B** | Defining "what happens when translation missing" belongs in runtime delivery contract. | ADR A stops at compiled identity presence; ADR B owns resolution semantics. |
| **Scope creep into D26.17** | Choice interpolation touches both identity (placeholder in source text) and runtime delivery. | Defer to ADR B unless ADR A only states "identity applies to static label text" as boundary. |
| **Compile processor bypass** | ADR-012 D17.3 optional processor could mutate identity post-compile, undermining guarantees. | ADR A should state processor relationship to identity contract. |
| **Over-unification** | Forcing identical authoring syntax for `[id:]` on choices may conflict with choice line parser constraints documented in prior gap analysis. | ADR A defines contract outcomes, not syntax; but must not assume syntax without authoring ADR amendment path. |

---

## 4. Question-by-Question Architectural Exploration

Each subsection ends with a **Recommended for inclusion in ADR A** line. These are recommendations for the ADR author, not accepted architecture.

---

### Q1 — What translation identity must exist in compiled data before runtime?

**Context:** ADR-020 D26.6 requires stable translation identity for localized authored **text**. ADR-003 D3.8 gives LINE a `translation_key`; CHOICE has no analogous artifact today. Every `CompiledLine` has shared `id` (line ID) used for traversal and save/resume (ADR-011 D12.2).

#### Alternative 1A — Dedicated translation identity distinct from line ID (LINE pattern extended)

Each localized text surface (LINE body, each CHOICE label) carries its own translation identity artifact in compiled data, separate from traversal `id`.

| | |
|---|---|
| **Advantages** | Mirrors existing LINE model; translation catalogs decoupled from graph edits; line ID can change wiring without breaking translations if translation identity is author-stable. |
| **Disadvantages** | Two identifiers per node; authors must understand line ID vs translation identity; schema change on CHOICE (D25.2). |
| **Consequences** | ADR-003/005/004 amendments; golden snapshots change when implemented. |
| **Compatibility** | LINE `translation_key` already exists; extend parallel artifact to CHOICE. |
| **Ownership** | Compiler generates/stores; Runtime consumes per ADR B. |
| **ADR-020** | Aligns with D26.6 separate identity for authored text objects. |
| **D25.2** | **Yes** — `CompiledLine` schema change for CHOICE. |

#### Alternative 1B — line ID serves as translation identity for all surfaces

Translation lookup uses the existing per-node `id` (author `[id:]` or `{path}::{line}`) for both LINE and CHOICE.

| | |
|---|---|
| **Advantages** | No new schema artifact; D13.2 fallback already defines line ID generation; single identifier for traversal and translation. |
| **Disadvantages** | ADR-003 already stores `translation_key` on LINE **in addition to** `id` — two fields today; unification may break existing LINE translation catalogs keyed to `translation_key`; conflates save/resume cursor identity with catalog identity; moving a line changes fallback translation key. |
| **Consequences** | Would require reconciling why LINE has both `id` and `translation_key` today; potential LINE breaking change. |
| **Compatibility** | Poor for existing LINE unless `translation_key` is deprecated with migration — high blast radius. |
| **Ownership** | Compiler already generates `id`; translation identity = `id`. |
| **ADR-020** | Partially aligns (stable identity) but fights existing LINE dual-field model. |
| **D25.2** | **Yes** if LINE model is unified/deprecated; **Maybe** if only CHOICE adopts line_id-as-key while LINE keeps translation_key (inconsistent). |

#### Alternative 1C — Unified translation identity concept with surface-specific storage rules

One architectural concept ("translation identity") applies to all localized text surfaces; LINE retains existing storage binding; CHOICE gains equivalent binding without necessarily sharing the same serialized name (contract-level unification only).

| | |
|---|---|
| **Advantages** | One author-facing concept; preserves LINE compatibility; explicit extension path for choices and future surfaces. |
| **Disadvantages** | ADR A must define the concept abstractly; implementers map to schema (D25.2 still required). |
| **Consequences** | Cleanest documentation model; schema work deferred to implementation ADR/amendments. |
| **Compatibility** | LINE unchanged at contract level; CHOICE added. |
| **Ownership** | Compiler owns generation per surface rules under one concept. |
| **ADR-020** | Strong alignment with D26.6 and identity-mechanism rule. |
| **D25.2** | **Yes** for CHOICE storage; LINE may be clarification-only. |

**Recommended for inclusion in ADR A:** **Alternative 1C** — adopt a unified **translation identity** concept for all localized authored text surfaces; require compiled data to preserve that identity for LINE (existing) and CHOICE (new); do not conflate translation identity with traversal `id` without an explicit compatibility decision (see Q3).

---

### Q2 — Is author-provided identity required, optional, or forbidden per surface?

#### LINE body

| Policy | Advantages | Disadvantages |
|--------|------------|---------------|
| **Optional** (status quo, D13.2) | Low author friction; fallback for drafts; matches existing docs. | Shipped content may rely on fragile fallbacks. |
| **Required** | Stable catalogs for production; CI can enforce. | Breaks informal authoring workflows; stricter tooling. |
| **Forbidden** | Maximum uniformity via generated IDs only. | Breaks existing `[id:]` authoring and D13.2 override path. |

**Recommended for inclusion in ADR A:** **Optional author-provided identity for LINE**, with ADR A stating that **shipped/localized production content SHOULD use author-provided identity** (restates D26.6 lifetime guidance without making it a compile error).

#### Choice labels

| Policy | Advantages | Disadvantages |
|--------|------------|---------------|
| **Optional** | Consistent with LINE; choice lines gain `[id:]` when authoring is extended. | New surface may ship with fragile fallbacks. |
| **Required** | Forces stable choice keys before compile success. | Heavy-handed for v1; authoring syntax must exist first. |
| **Forbidden (generated only)** | Simple author experience; no new authoring syntax required at contract level. | Authors cannot stabilize choice keys across refactors; conflicts with D26.6 "SHOULD prefer author-provided IDs." |

**Recommended for inclusion in ADR A:** **Optional author-provided identity for choice labels**, same lifetime guidance as LINE. **Forbidden** is inconsistent with D26.6; **Required** is architecturally valid but **not recommended** for v1 contract strictness — defer required-policy to a future stricter tier if needed.

---

### Q3 — Relationship between LINE `translation_key` / `[id:]` and choice-label identity

#### Alternative 3A — Same mechanism, same rules

Choices use identical author override and fallback rules as LINE (`[id:]` semantics extended to choice authoring; same fallback formula).

| | |
|---|---|
| **Advantages** | One rule set; authors learn once; unified tooling. |
| **Disadvantages** | Authoring format currently documents `[id:]` only on `Speaker:` lines; choice lines have distinct syntax — contract assumes authoring amendment without designing syntax here. |
| **D25.2** | Authoring + compiled schema. |

#### Alternative 3B — Parallel mechanism, different rules

Separate identity namespace or fallback formula for choices (e.g., choice-group-scoped keys).

| | |
|---|---|
| **Advantages** | Avoids parser/authorship coupling to LINE `[id:]` position. |
| **Disadvantages** | Two rule sets; translation pipeline complexity; weaker unified model. |

#### Alternative 3C — Unified concept, surface-specific authoring expression

One translation identity concept; LINE and CHOICE express author overrides through surface-appropriate authoring (details in ADR-004 amendment, not ADR A); compiler applies same stability/uniqueness/fallback **principles** with surface-appropriate binding.

| | |
|---|---|
| **Advantages** | Balances unified model with practical authoring differences; ADR A stays syntax-agnostic. |
| **Disadvantages** | Requires careful ADR-004 amendment to avoid ambiguity. |

#### Alternative 3D — translation_key equals line id for LINE today; choices adopt line id only

Collapse LINE dual-field model over time.

| | |
|---|---|
| **Advantages** | Theoretical simplicity. |
| **Disadvantages** | Breaking LINE compatibility; outside ADR A minimal scope. |

**Recommended for inclusion in ADR A:** **Alternative 3C** — unified translation identity **concept** with **surface-specific authoring expression** to be defined in ADR-004 amendment; **same principles** (author override, deterministic fallback, stability, uniqueness) for LINE and CHOICE. Explicitly state whether translation identity and traversal `id` are the same value or correlated — **recommended: allow them to differ** (LINE already has both `id` and `translation_key` in accepted schema, implying they may differ or mirror by compiler policy without ADR A prescribing mirroring).

---

### Q4 — Uniqueness scope for translation identities

#### Alternative 4A — Per `.dlg` file (namespaced by source path)

| | |
|---|---|
| **Advantages** | Matches single-file-per-conversation scope (D4.9); fallback already uses `source_path`; collisions across files impossible. |
| **Disadvantages** | Duplicate author keys in different files are allowed — translation catalogs must namespace or collide. |

#### Alternative 4B — Per project (global across all compiled dialogue)

| | |
|---|---|
| **Advantages** | Single flat translation catalog; no accidental duplicate keys across NPCs. |
| **Disadvantages** | Stricter author burden; compile must cross-check all dialogue resources (no cross-file import in v1, but catalog is project-wide). |

#### Alternative 4C — Per project with optional author prefix convention (non-normative)

| | |
|---|---|
| **Advantages** | Human convention reduces collisions without compiler cross-file validation. |
| **Disadvantages** | Not enforceable; weak architectural guarantee. |

#### Alternative 4D — Tiered: per-file uniqueness enforced at compile; project-wide uniqueness recommended

| | |
|---|---|
| **Advantages** | Enforceable minimum; aligns with compile-at-import per file; allows project catalog discipline via game pipeline. |
| **Disadvantages** | Cross-file duplicate author IDs still possible. |

**Recommended for inclusion in ADR A:** **Alternative 4D** — compiler **guarantees uniqueness within a compiled dialogue resource**; **project-wide uniqueness is a game/translation-pipeline concern** unless a future ADR adds cross-resource compile validation (out of v1 scope per D5.5 no cross-file imports).

---

### Q5 — Compiler guarantees when author-provided identity is missing

#### Alternative 5A — Deterministic fallback identical to LINE rule (`{source_path}::{source_line_number}`)

| | |
|---|---|
| **Advantages** | Consistent with D13.2; proven for LINE. |
| **Disadvantages** | For CHOICE, multiple choices on adjacent lines have distinct line numbers — works; reordering choices changes keys. |

#### Alternative 5B — Deterministic fallback derived from choice group context

Fallback incorporates parent LINE or first CHOICE in group identity plus option index.

| | |
|---|---|
| **Advantages** | Stable within group if group anchor stable. |
| **Disadvantages** | Second rule set; harder for authors to predict keys; departs from LINE simplicity. |

#### Alternative 5C — Fallback uses traversal line id only

Translation identity defaults to node's `id`.

| | |
|---|---|
| **Advantages** | Single identifier. |
| **Disadvantages** | Ties translation to graph id policy; see Q1/B risks. |

**Recommended for inclusion in ADR A:** **Alternative 5A** for all localized text surfaces — **same fallback principle as D13.2** applied per authored source location of each localized text object (LINE line, each CHOICE line). Document that fallback identities are **development-tier** stability per D26.6.

---

### Q6 — Compiler guarantees when author-provided identity conflicts

#### Alternative 6A — Fail compile (error) on duplicate translation identity within resource

| | |
|---|---|
| **Advantages** | Prevents silent catalog overwrites; strict data integrity. |
| **Disadvantages** | Blocks import until fixed. |

#### Alternative 6B — Warn in editor import, error in `--strict` CI

| | |
|---|---|
| **Advantages** | Matches ADR-012 D15.3 tiered validation pattern. |
| **Disadvantages** | Local import may produce ambiguous resources. |

#### Alternative 6C — Warn only

| | |
|---|---|
| **Advantages** | Never blocks.workflow. |
| **Disadvantages** | Violates "invalid dialogue never becomes .tres" spirit (D5.3) for identity conflicts. |

#### Alternative 6D — Fail on duplicate author IDs; allow duplicate fallbacks only if impossible (fallback should be unique by line number)

| | |
|---|---|
| **Advantages** | Author duplicates are errors; fallback uniqueness by construction if one identity per source line. |
| **Disadvantages** | Must handle edge case: two localized strings on same line (not possible for LINE/CHOICE text today). |

**Recommended for inclusion in ADR A:** **Alternative 6B** — duplicate **author-provided** translation identity within a compiled dialogue resource is an **error under `--strict`** and a **warning** on local editor import, **aligned with ADR-012 D15.3 tiering**. **Invalid identity shape** (empty, illegal characters if shape rules are adopted in ADR A) should be **error** in all tiers.

---

### Q7 — Compile-time failure policy for identity validation errors

#### Alternative 7A — Identity errors always fail import

| | |
|---|---|
| **Advantages** | Simplest; no invalid `.tres`. |
| **Disadvantages** | Harsh for work-in-progress. |

#### Alternative 7B — Tiered per D15.3 (duplicate author ID: warn local / error strict; missing identity impossible if compiler always generates)

| | |
|---|---|
| **Advantages** | Consistent with existing validation architecture. |
| **Disadvantages** | More complex policy table in ADR A. |

#### Alternative 7C — Identity validation delegated entirely to game CI

| | |
|---|---|
| **Advantages** | Minimal compiler scope. |
| **Disadvantages** | Violates D26.5 compiler ownership of validation. |

**Recommended for inclusion in ADR A:** **Alternative 7B** — identity validation follows **tiered validation** already accepted in ADR-012; ADR A defines which identity faults are warn vs error per tier. **Compiler always generates identity** (no "missing identity" fault) — generation is mandatory per D26.5.

---

### Q8 — What compiled data must preserve besides translation identity

#### Alternative 8A — Identity + authored source text (authoring language)

| | |
|---|---|
| **Advantages** | Supports debug (D14.3), fallback display policy in ADR B, re-export workflows; matches D26.7 "preserves source text." |
| **Disadvantages** | Larger compiled resources; source text duplication per node. |

#### Alternative 8B — Identity only; source text recoverable from `raw_text` on resource

| | |
|---|---|
| **Advantages** | Smaller per-node payload. |
| **Disadvantages** | Runtime/compiler must parse `raw_text` for fallback — conflicts with "runtime does not parse .dlg" if raw_text is full file; extracting substring still needs offset map. |

#### Alternative 8C — Identity + source text for localized surfaces only

| | |
|---|---|
| **Advantages** | Targeted preservation. |
| **Disadvantages** | LINE already has `text`; CHOICE has `text` — may already satisfy without new contract. |

**Recommended for inclusion in ADR A:** **Alternative 8C** — compiled data **must preserve translation identity and authored source text for each localized text surface**. Note: accepted schema already stores `text` on LINE and CHOICE; ADR A **clarifies architectural obligation** (preservation for debug/fallback contract) rather than inventing new storage. **`raw_text` on CompiledDialogue** remains the file-level debug artifact per D3.5.

---

### Q9 — Compatibility when compiled resource lacks required localization identity

Applies when older `.tres` predate choice identity contract.

#### Alternative 9A — `format_version` bump; loader rejects unsupported versions

| | |
|---|---|
| **Advantages** | Explicit; no silent partial behavior. |
| **Disadvantages** | Requires reimport; games must rebuild assets. |

#### Alternative 9B — Compiler version gate only; runtime accepts missing choice identity with degraded behavior

| | |
|---|---|
| **Advantages** | Soft transition. |
| **Disadvantages** | Degraded behavior is **runtime policy** — belongs in ADR B, not ADR A. |

#### Alternative 9C — Mandatory reimport on framework upgrade; no runtime backward compatibility for pre-contract CHOICE nodes

| | |
|---|---|
| **Advantages** | Clear operational rule; no partial schema. |
| **Disadvantages** | Migration is process, not code — ADR A states expectation only. |

#### Alternative 9D — LINE backward compatible always; CHOICE identity required only for newly compiled resources after contract effective date

| | |
|---|---|
| **Advantages** | Minimal LINE risk; CHOICE forward-only. |
| **Disadvantages** | Two classes of CHOICE resources until reimported. |

**Recommended for inclusion in ADR A:** **Alternative 9D combined with 9A principle** — **LINE resources remain compatible** with existing identity rules; **CHOICE nodes in resources compiled before the contract effective version lack required identity and are architecturally invalid for localized choice delivery** — detection via **`format_version` or equivalent schema version signal** (numeric value not decided here); **remediation is reimport**, not runtime inference. ADR A does not define loader behavior — states **compatibility expectation** only.

---

### Q10 — Verification expectations (authoring / compiler / data layer)

Architectural properties to verify (not test implementation):

| Property | Layer |
|----------|-------|
| Every localized text surface in a compiled resource has translation identity | Compiler / data |
| Author-provided identities are stable across recompile when source unchanged | Compiler |
| Duplicate author-provided identities are flagged per tier policy | Compiler |
| Fallback identity is deterministic for same source location | Compiler |
| Compiled resource remains language-neutral (identity ≠ translated string) | Data |
| LINE existing keys still validate after contract | Compiler regression |
| CHOICE group nodes each carry identity after contract implementation | Compiler / data |

**Recommended for inclusion in ADR A:** Adopt the property list above as **architectural verification expectations** referencing ADR-012 layers; golden compile snapshot regression (D16.4) is expected to change when identity contract is implemented — ADR A states expectation, not snapshot content.

---

### Q11 — Does speaker `speaker_id` require compiled identity beyond D26.16?

#### Alternative 11A — No compiled translation identity; `speaker_id` is the identity (Presentation-resolved)

| | |
|---|---|
| **Advantages** | Matches accepted D26.16; no schema change; no D25.2 for speaker. |
| **Disadvantages** | Future `SpeakerManifest` (05-open-questions) needs new ADR. |

#### Alternative 11B — Compiled record of speaker display key separate from `speaker_id`

| | |
|---|---|
| **Advantages** | Supports alias speakers, display vs internal id. |
| **Disadvantages** | Scope creep; D25.2; reverses simplicity. |

#### Alternative 11C — ADR A documents boundary only: speakers excluded from compiled-identity generation

| | |
|---|---|
| **Advantages** | Clarifies ADR A scope without new decision. |
| **Disadvantages** | None significant. |

**Recommended for inclusion in ADR A:** **Alternative 11C / 11A** — speaker display names **do not** receive compiled translation identity in ADR A; **`speaker_id` remains the identity** for Presentation `tr()` per D26.16. Future `SpeakerManifest` is a **separate future ADR** (05-open-questions).

---

### Q12 (Planning A.11) — Relationship to optional compile processor (ADR-012 D17.3)

#### Alternative 12A — Processor may not alter translation identity

| | |
|---|---|
| **Advantages** | Identity guarantees remain trustworthy. |
| **Disadvantages** | Limits advanced game hooks. |

#### Alternative 12B — Processor may transform identity with explicit post-validation

| | |
|---|---|
| **Advantages** | Flexibility for mods/dlc. |
| **Disadvantages** | Identity contract becomes non-deterministic without re-validation rules. |

#### Alternative 12C — Processor out of scope for v1 identity contract; using processor for identity is undefined

| | |
|---|---|
| **Advantages** | Minimal ADR A scope. |
| **Disadvantages** | Ambiguous for processor users. |

**Recommended for inclusion in ADR A:** **Alternative 12A** — compile processor **must not modify or replace translation identity** for localized text surfaces; it may modify other line properties only. If identity mutation is needed in future, require explicit ADR amendment.

---

## 5. Proposed ADR A Section Analysis (Planning §9)

| Proposed section | Analysis status |
|------------------|-----------------|
| A.1 Context / ADR-020 relationship | Covered by §2 constraints, §1 assumptions |
| A.2 Localized text surfaces in scope | Q1, Q11; LINE + CHOICE in scope; speaker excluded from compiled identity |
| A.3 Translation identity contract | Q1, Q2, Q3, Q5 |
| A.4 Stability, uniqueness, language-neutrality | Q4, Q5, §2 D26.6 |
| A.5 Authoring responsibilities | Q2, Q3 — syntax deferred to ADR-004 amendment |
| A.6 Compiler generation/validation | Q5, Q6, Q7 |
| A.7 Compiled-data preservation | Q8 |
| A.8 Speaker boundary | Q11 |
| A.9 Compatibility/versioning | Q9 |
| A.10 Verification expectations | Q10 |
| A.11 Compile processor | Q12 |
| A.12 Consequences / amendments | Planning §6; blast radius in §8 |
| A.13 D25.2 gate | Q1, Q9; §8 |

---

## 6. Open Questions Remaining After Analysis

| # | Question | Status |
|---|----------|--------|
| O1 | Exact authoring expression for choice author-provided identity | **Remains for ADR-004 amendment** — ADR A defines contract, not syntax |
| O2 | Whether translation identity must equal traversal `id` for LINE going forward | Analysis recommends **allow divergence** (status quo); ADR A should state explicitly |
| O3 | Numeric `format_version` increment policy | **Deferred to implementation planning** — ADR A states bump required, not number |
| O4 | Identity shape constraints (character set, length) | **Open** — recommend ADR A adopt minimal rule: non-empty string identity |
| O5 | Cross-resource duplicate author IDs at project level | **Deferred** — game pipeline concern per Q4 recommendation |

---

## 7. Questions Deferred to ADR B

Per planning outline §8 and ADR-020 scope boundaries:

| Topic | Why ADR B |
|-------|-----------|
| Runtime translation lookup semantics | Runtime delivery contract |
| Missing-translation behavior | Runtime policy when catalog lacks identity entry |
| `ConversationStep` localized string guarantees | DTO delivery semantics |
| Locale-switch refresh including `AwaitingChoice` | Phase behavior |
| Whether locale refresh re-runs interpolation (**D26.18**) | Runtime refresh semantics |
| Whether choice labels may contain `{brace}` interpolation (**D26.17**) | **Recommended defer to ADR B** — touches delivery and placement order, not identity generation; ADR A may state identity applies to static choice label text as boundary |
| Degraded behavior for pre-contract CHOICE resources at runtime | Runtime/load policy |

---

## 8. Questions Deferred Beyond ADR B

| Topic | Source |
|-------|--------|
| Portrait text localization | D11.4, D25.4 |
| Screen reader / narration text | D23.4, D25.5 |
| Custom line type localization | D17.2 |
| `SpeakerManifest` / compiled speaker identity | 05-open-questions |
| Project-wide cross-file identity validation | D5.5 no cross-file imports |
| Translation authoring tooling | ADR-020 non-goals D26.15 |
| Pluralization / grammar policy | ADR-020 non-goals |

---

## 9. Dependency Analysis — What ADR A Must Settle Before ADR B

ADR B **cannot** be drafted until ADR A accepts at minimum:

| Settlement | Enables ADR B to define |
|------------|-------------------------|
| Unified translation identity concept for LINE + CHOICE | What Runtime looks up when resolving text |
| Compiler mandatory identity generation for localized text | No runtime inference from source |
| Preservation of source text + identity on compiled nodes | Fallback/missing-translation policies |
| Uniqueness scope within resource | Catalog collision assumptions |
| Tiered validation policy for identity faults | Whether ADR B can assume identity always present on new compiles |
| Compatibility rule for legacy CHOICE resources | Whether ADR B must define degraded mode vs hard fail |
| Speaker excluded from compiled identity | ADR B presenter assumptions for speaker `tr()` |
| Compile processor must not mutate identity | ADR B can trust compiled identity |
| Explicit non-scope: missing-translation, locale refresh, D26.17/18 delivery aspects | Clean ADR B boundary |

ADR B **does not need** ADR A to decide: catalog file format, lookup algorithm, step delivery layout, or phase transition mechanics.

---

## 10. ADR-019 D25.2 Implications Summary

| Contract | Triggered by ADR A acceptance? | Notes |
|----------|----------------------------------|-------|
| `CompiledLine` schema | **Yes** — CHOICE localized text needs identity binding | LINE may be clarificatory |
| `CompiledDialogue` / `format_version` | **Yes** — compatibility signaling for CHOICE identity | Numeric bump not designed here |
| `ConversationStep` | **No** — ADR B |
| `ConversationPhase` | **No** — ADR B |
| `IDialoguePresenter` | **No** — speaker stays Presentation per D26.16 |

ADR A acceptance **authorizes** the architectural contract that implementation must satisfy; **implementation remains prohibited** until ADR A is Accepted and implementation work is explicitly planned under D25.2.

---

## 11. Completeness Check — Planning Outline Coverage

| Planning item | Analyzed in |
|---------------|-------------|
| Q1 Identity in compiled data | §4 Q1 |
| Q2 Author-provided required/optional | §4 Q2 |
| Q3 LINE vs choice relationship | §4 Q3 |
| Q4 Uniqueness scope | §4 Q4 |
| Q5 Missing author ID fallback | §4 Q5 |
| Q6 Identity conflicts | §4 Q6 |
| Q7 Compile failure policy | §4 Q7 |
| Q8 Preservation besides identity | §4 Q8 |
| Q9 Legacy compatibility | §4 Q9 |
| Q10 Verification expectations | §4 Q10 |
| Q11 Speaker boundary | §4 Q11 |
| A.11 Compile processor | §4 Q12 |
| Assumptions | §1 |
| Constraints from ADR-020 | §2 |
| Architectural risks | §3 |
| Open questions after analysis | §6 |
| Defer to ADR B | §7 |
| Defer beyond ADR B | §8 |
| ADR B dependencies | §9 |
| D25.2 implications | §10 |
| Proposed sections A.1–A.13 | §5 |

**All planning outline items for ADR A have been analyzed.**

---

## 12. Summary of Recommendations for ADR A Authorship

*Recommended for inclusion in ADR A — not accepted architecture.*

1. **Unified translation identity concept** for LINE body and choice labels (Q1 → 1C).
2. **Optional author-provided identity** for both surfaces with SHOULD prefer stable author IDs for shipped content (Q2).
3. **Unified principles, surface-specific authoring expression** (Q3 → 3C); clarify identity vs traversal `id` may differ.
4. **Uniqueness enforced per compiled resource**; project-wide is game pipeline concern (Q4 → 4D).
5. **D13.2-equivalent fallback** per localized text source location (Q5 → 5A).
6. **Tiered duplicate detection** aligned with ADR-012 D15.3 (Q6 → 6B, Q7 → 7B).
7. **Preserve identity + source text** on localized nodes; clarify existing `text` fields satisfy obligation (Q8 → 8C).
8. **LINE backward compatible; CHOICE identity required only post-contract version; reimport remediation** (Q9 → 9D+9A).
9. **Architectural verification property list** for compiler/data layers (Q10).
10. **Speakers excluded from compiled identity**; `speaker_id` only per D26.16 (Q11).
11. **Compile processor must not alter translation identity** (Q12 → 12A).
12. **D26.17 and D26.18 deferred to ADR B** with ADR A boundary: identity applies to static authored label text.

---

*End of design analysis. This document is not an ADR. No implementation is authorized.*
