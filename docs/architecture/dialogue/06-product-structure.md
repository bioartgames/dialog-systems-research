# Product Structure

**Decisions:** D20.1–D20.6 (ADR-014)

---

## Dialogue Framework product

The **Dialogue Framework** is a single Godot addon product at `addons/dialogue_framework/` with two architectural subsystems:

| Subsystem | Path | Role |
|-----------|------|------|
| **Runtime** | `runtime/` | Headless execution: `ConversationController`, `DialogueRunner`, phases, `ConversationStep`, conditions, commands, localization resolution, snapshots, **`IDialoguePresenter` interface** |
| **Presentation** | `presentation/` | Dialogue-specific UI technology: presenter implementations, layouts, themes, tag/timing policy, reference scenes and resources |
| **Compiler** | `compiler/` | `.dlg` → `CompiledDialogue` (editor / CI) |
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

### Runtime owns

- Dialogue traversal, branching, phases
- `ConversationController`, `DialogueRunner`
- `ConversationStep` delivery
- Condition evaluation, command dispatch
- Localization **resolution** into steps
- `DialogueSnapshot` helpers
- **`IDialoguePresenter` contract** (interface only)

### Presentation owns

- `IDialoguePresenter` **implementations**
- Typewriter / reveal policy
- `#voice`, `#time`, `#time=auto` interpretation
- Choice and speaker presentation UX
- Dialogue layouts, themes, presentation resources/scenes
- Future portrait presentation (when ADRs expand scope)
- Native Godot UI path (required baseline)
- Optional Ui React integration path

### Ui React owns

- `UiState`, bindings, animations, generic controls — **no dialogue semantics**

### Game owns

- `GameContext`, gameplay commands, orchestration
- Wiring presenter into `ConversationController.start()`
- Input routing policy, pausing player, game-specific overrides

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

- [decisions/014-product-structure-and-presentation.md](decisions/014-product-structure-and-presentation.md) — ADR
- [decisions/010-ui-and-presenter.md](decisions/010-ui-and-presenter.md) — Presenter policy (amended by ADR-014)
- [04-runtime-and-integration.md](04-runtime-and-integration.md) — Runtime integration flows
- [addons/dialogue_framework/docs/game_presenter.md](../../../addons/dialogue_framework/docs/game_presenter.md) — Contract and presentation guide
