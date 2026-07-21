# Product Structure

**Decisions:** D20.1–D20.6 (ADR-014)

---

## Dialogue Framework product

The **Dialogue Framework** is a single Godot addon product at `addons/dialogue_framework/` with two architectural subsystems:

| Subsystem | Path | Role |
|-----------|------|------|
| **Runtime** | `runtime/` | Headless execution: `ConversationController`, `DialogueRunner`, phases, `ConversationStep`, conditions, commands, localized delivery of compiled-identity authored text (line body, choice labels), snapshots, **`IDialoguePresenter` interface** |
| **Presentation** | `presentation/` | Dialogue-specific UI technology: presenter implementations, layouts, themes, tag/timing policy, reference scenes and resources |
| **Compiler** | `compiler/` | `.dlg` → `CompiledDialogue` (editor / CI); translation-identity generation, validation, and preservation for localized text surfaces (ADR-021) |
| **Data** | `data/` | Shared DTOs, manifests, enums |

Runtime and Presentation are **siblings**. Runtime never imports Presentation.

## Core invariants (normative)

1. **Runtime SHALL NOT import Presentation.**
2. **Presentation MAY depend on Runtime but SHALL remain optional to adopt.**

See [decisions/014-product-structure-and-presentation.md](decisions/014-product-structure-and-presentation.md) for the full ADR.

---

## Related products in this repository

| Addon | Role |
|-------|------|
| **`addons/ui_react/`** | Generic reactive UI infrastructure (optional Presentation adapter) |
| **`game/`** | Game content, `GameContext`, command handlers, orchestration, overrides |

---

## Dependency rules (normative)

```
                Runtime
                   ▲
                   │
             Presentation
              ▲         ▲
              │         │
     Native Godot UI   Ui React (optional)
```

| From | To | Allowed |
|------|-----|---------|
| Presentation | Runtime | Yes |
| Presentation | Native Godot UI | Yes |
| Presentation | Ui React | Yes (optional) |
| Game | Runtime | Yes |
| Game | Presentation | Yes (wire presenter) |
| Runtime | Presentation | **No** |
| Runtime | Ui React | **No** |
| Ui React | Runtime / dialogue concepts | **No** |

---

## Responsibility summary

### Compiler owns

- `.dlg` → `CompiledDialogue` compile-at-import pipeline
- Translation-identity **generation**, **validation**, and **preservation** for localized authored text surfaces (line body, choice labels) per ADR-021

### Runtime owns

- Dialogue traversal, branching, phases
- `ConversationController`, `DialogueRunner`
- `ConversationStep` delivery
- Condition evaluation, command dispatch
- Translation **resolution and localized delivery** of compiled-identity authored **text** (line body, choice labels), locale refresh, and missing-translation fallback (ADR-020 D26.5, ADR-022 D28.19). Speaker display-name resolution is **not** Runtime-owned (see Presentation).
- `DialogueSnapshot` helpers (coordinates only; language-neutral)
- **`IDialoguePresenter` contract** (interface only)

### Presentation owns

- `IDialoguePresenter` **implementations**
- Typewriter / reveal policy
- `#voice`, `#time`, `#time=auto` interpretation
- Choice and speaker presentation UX
- **Speaker display-name resolution** via `tr(speaker_id, "speakers")` — the single Presentation translation-resolution case (ADR-020 D26.16); displays Runtime-delivered localized line/choice text without catalog lookup
- Dialogue layouts, themes, presentation resources/scenes
- Future portrait presentation (when ADRs expand scope)
- Native Godot UI path (required baseline)
- Optional per-control Ui React via layout slot variants (not a separate presenter path)

### Ui React owns

- `UiState`, bindings, animations, generic controls — **no dialogue semantics**

### Game owns

- `GameContext`, gameplay commands, orchestration
- Wiring presenter into `ConversationController.start()`
- When conversations run; pausing player; applying player settings to Presentation resources
- Translation catalogs, active-locale selection, and delegated interpolation values (ADR-020 D26.5, ADR-022 D28.7)
- Optionally overriding or disabling default presentation input when UI layers compete (see ADR-016)

---

## Import rules (`presentation/`)

1. Code under `presentation/` may `preload`/`extends`/`class_name` from `runtime/` and `data/`.
2. Code under `runtime/` must **not** reference `presentation/` paths.
3. `compiler/` and `data/` must **not** reference `presentation/`.
4. Presentation must not introduce dialogue execution logic (no graph traversal, no phase mutation except via public Runtime API from presenter implementations).

---

## Testing

| Layer | Test style |
|-------|------------|
| Runtime, compiler, data | Headless GUT (no scene tree required) |
| Presentation | Integration / scene tests; may use mock `ConversationStep` |
| Game | Showcase / smoke tests |

---

## Related documents

- [07-presentation-product-spec.md](07-presentation-product-spec.md) — Presentation Product Specification v1 (frozen)
- [decisions/014-product-structure-and-presentation.md](decisions/014-product-structure-and-presentation.md) — ADR
- [decisions/015-presentation-product-concepts.md](decisions/015-presentation-product-concepts.md) — Layout, Theme, Policy, Input
- [decisions/016-presentation-input-ownership.md](decisions/016-presentation-input-ownership.md) — Dialogue UX input
- [decisions/017-presentation-accessibility.md](decisions/017-presentation-accessibility.md) — Dialogue a11y
- [decisions/018-presentation-consumer-customization.md](decisions/018-presentation-consumer-customization.md) — Editor-first boundary
- [decisions/019-presentation-growth-constraints.md](decisions/019-presentation-growth-constraints.md) — Asset-based growth
- [decisions/010-ui-and-presenter.md](decisions/010-ui-and-presenter.md) — Presenter policy (amended by ADR-014)
- [04-runtime-and-integration.md](04-runtime-and-integration.md) — Runtime integration flows
- [decisions/020-localization-architecture.md](decisions/020-localization-architecture.md) — Localization ownership model
- [decisions/022-localized-runtime-delivery-locale-switching.md](decisions/022-localized-runtime-delivery-locale-switching.md) — Runtime/Presentation localization split
- [addons/dialogue_framework/docs/game_presenter.md](../../../addons/dialogue_framework/docs/game_presenter.md) — Contract and presentation guide
