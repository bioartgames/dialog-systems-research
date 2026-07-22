# Implementation DAG

Living index of implementation plans and backlog sync for this repository.

Per project knowledge hierarchy: **Vision → GDD → Architecture → ADRs → Implementation Plan (DAG) → Implementation → Developer Guide**.

---

## Active plans

| Plan | Status | ADR | Linear |
|------|--------|-----|--------|
| [ADR-024 Integration kit (D30.4)](architecture/dialogue/planning/adr-024-integration-kit-implementation-plan.md) | IK-0–IK-6 Done; IK-7 optional | [ADR-024](architecture/dialogue/decisions/024-optional-game-integration-kit.md) | [CRG-345](https://linear.app/lock-and-key/issue/CRG-345/epic-optional-game-integration-kit-adr-024) |

---

## ADR-024 Integration kit DAG (`IK-*`)

```text
IK-0 scaffold+boundary
 ├─► IK-1 ResourceGameContext ─► IK-2 Command bridge ─┐
 └─► IK-3 Load helper ────────────────────────────────┼─► IK-4 Starter ─► IK-5 Kit tests ─┬─► IK-6 Docs
                                                       │                                  └─► IK-7 Showcase migrate (optional)
```

| Local ID | Title | Linear ID | Status |
|----------|-------|-----------|--------|
| — | Epic: Optional Game Integration Kit (ADR-024) | [CRG-345](https://linear.app/lock-and-key/issue/CRG-345/epic-optional-game-integration-kit-adr-024) | Backlog |
| IK-0 | Package scaffold + boundary tests | [CRG-346](https://linear.app/lock-and-key/issue/CRG-346/ik-0-integration-package-scaffold-boundary-tests) | Done |
| IK-1 | ResourceGameContext | [CRG-347](https://linear.app/lock-and-key/issue/CRG-347/ik-1-resourcedictionary-backed-gamecontext) | Done |
| IK-2 | Command bridge | [CRG-348](https://linear.app/lock-and-key/issue/CRG-348/ik-2-command-bridge-resource-registrar) | Done |
| IK-3 | CompiledDialogue load helper | [CRG-350](https://linear.app/lock-and-key/issue/CRG-350/ik-3-compileddialogue-load-helper) | Done |
| IK-4 | Conversation starter Node | [CRG-349](https://linear.app/lock-and-key/issue/CRG-349/ik-4-conversation-starter-node) | Done |
| IK-5 | Kit GUT tests | [CRG-351](https://linear.app/lock-and-key/issue/CRG-351/ik-5-integration-kit-gut-tests) | Done |
| IK-6 | Adoption + translation docs | [CRG-353](https://linear.app/lock-and-key/issue/CRG-353/ik-6-integration-kit-adoption-translation-docs) | Done |
| IK-7 | Showcase dual-path migrate | [CRG-352](https://linear.app/lock-and-key/issue/CRG-352/ik-7-showcase-dual-path-migrate-onto-integration-kit) | Backlog |

---

## Historical / Linear CRG sync

The Dialogue Framework original implementation backlog is mirrored in:

- Linear team **Cloud Roost Games**, project **Dialogue Framework** (and **Dialogue Framework — Remaining Work** for post-v1 epics)
- Repo edge map: `tools/crg_relations.json`
- Validator: `tools/validate_dag_sync.py` (fixed CRG ID ranges — does not automatically include Remaining Work epics)

New ADR-driven work may live as Remaining Work epics without expanding that validator until explicitly decided.

---

## Related

- [optional-game-integration-kit-adr-outline.md](architecture/dialogue/planning/optional-game-integration-kit-adr-outline.md) — Board planning (resolved)
- [024-optional-game-integration-kit.md](architecture/dialogue/decisions/024-optional-game-integration-kit.md) — Accepted ADR
