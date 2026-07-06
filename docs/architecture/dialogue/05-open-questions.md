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
- v1 uses **subtitle + speaker name** via game presenter or world UI
- Speaker display via `tr(speaker_id, "speakers")` only; no `SpeakerManifest` in v1 (D13.3)

When portraits are added, expect new ADRs covering tag syntax, `ConversationStep` fields, and presenter contract changes.

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
