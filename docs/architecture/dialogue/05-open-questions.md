# Open Questions and Deferred Work

**Decisions:** D19.1–D19.4, portrait follow-up (D11.4)

---

## Status

**No open architecture blockers.** All v1 design decisions are finalized. Items below are explicitly deferred—not unresolved questions.

---

## Visual editor (D19.1–D19.4)

| Item | Status |
|------|--------|
| Visual dialogue editor | Deferred indefinitely (D19.1) |
| `.dlg` text as canonical source | Permanent (D19.2) |
| Editor metadata on `CompiledLine` | Not in v1 (D19.3) |
| In-editor playtest | Deferred; use game run + tests (D19.4) |

v1 tooling is import-plugin only (D18.1). Authors use an external text editor (D18.3).

---

## Portraits and 3D presentation (D11.4)

Deferred to a future version:

- **No `#portrait` tag** in v1 authoring spec
- **No portrait field** on `ConversationStep` (omit entirely; not reserved)
- v1 uses **subtitle + speaker name** via Presentation or world UI
- Speaker display via `tr(speaker_id, "speakers")` only; no `SpeakerManifest` in v1 (D13.3)

When portraits are added, expect new ADRs covering tag syntax, `ConversationStep` fields, and presenter contract changes. Portrait display is subject to the **Runtime contract change gate** ([ADR-019 D25.2](decisions/019-presentation-growth-constraints.md), [architecture README](README.md#architecture-change-gate-d252)).

---

## Screen reader and narration (ADR-017 D23.4)

Deferred to a future version:

- Screen reader and narration pipeline integration is **out of v1 product scope**
- Any implementation requires a **future ADR** per [ADR-019 D25.2](decisions/019-presentation-growth-constraints.md) if it touches `ConversationStep`, `IDialoguePresenter`, or compiled dialogue schema

See [decisions/017-presentation-accessibility.md](decisions/017-presentation-accessibility.md) (D23.4) and [decisions/019-presentation-growth-constraints.md](decisions/019-presentation-growth-constraints.md) (D25.5).

---

## Localization (ADR-020, ADR-021, ADR-022)

The localization architecture is complete: ADR-020 (subsystem model), ADR-021 (compile-time identity contract), ADR-022 (runtime delivery and locale switching). Previously deferred questions are now resolved:

| Deferred question | Resolution |
|-------------------|-----------|
| **D26.17** — may choice labels contain interpolation? | **Resolved — excluded in v1**; choice labels are localized static text (ADR-022 D28.14). Permitting it requires a future ADR. |
| **D26.18** — does locale refresh re-run interpolation? | **Resolved**; LINE locale refresh re-resolves both localized body text and delegated interpolation values (ADR-022 D28.15). |

Remaining localization deferrals: portrait/screen-reader/narration/custom-line-type surfaces (future ADRs per ADR-020) and `SpeakerManifest` / compiled speaker identity (future ADR per this document; ADR-021 D27.12).

---

## Possible future extensions (not designed)

These are not commitments. Any implementation requires new architecture decisions:

- Cross-file `.dlg` imports (D5.5 excluded v1)
- Inline text conditionals (D8.4 excluded v1)
- Custom compiled line types (D17.2 excluded v1)
- Speaker registry / `SpeakerManifest`
- Manifest validation for `has_item` / `get_quest_state` IDs
- Nested simultaneous conversations (D2.4 excluded v1)
- Framework debug overlay (D14.4 — game provides debug UI)

---

## Related documents

- [00-project-goals.md](00-project-goals.md) — v1 non-goals
- [decisions/013-future-editor.md](decisions/013-future-editor.md) — ADR
- [decisions/020-localization-architecture.md](decisions/020-localization-architecture.md) — ADR
- [decisions/021-localized-authoring-compiled-identity.md](decisions/021-localized-authoring-compiled-identity.md) — ADR
- [decisions/022-localized-runtime-delivery-locale-switching.md](decisions/022-localized-runtime-delivery-locale-switching.md) — ADR
