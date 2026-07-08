# Project Goals

**Decisions:** D1.1–D1.6

---

## Purpose

Design a custom dialogue framework for a **MegaMan Legends–style 3D action RPG** (D1.4). The framework lives in `addons/dialogue_framework/` and is informed by research on Dialogic 2 and Dialogue Manager in this repository—not a fork of either plugin.

---

## Core principles

### Game-authoritative state (D1.1)

The game save and game systems own flags, items, and quests. The dialogue framework does not maintain a parallel variable namespace. This follows Dialogue Manager’s strength (single game-state source) and avoids Dialogic’s split between plugin variables and game state.

### Layered interpreter (D1.2)

```
ConversationController → DialogueRunner → ConversationStep DTO
```

- **Controller:** Public API, phase management, presenter wiring.
- **Runner:** Pure graph traversal; no UI or scene references.
- **DTO:** Presentation-neutral step boundary (inspired by DM’s `DialogueLine` pattern).

UI and persistent game state remain external to the runner. Presentation is a separate subsystem within the Dialogue Framework product (ADR-014); it is not part of Runtime.

### Compile at import (D1.3)

`.dlg` source files compile to `CompiledDialogue` `.tres` resources via Godot’s `EditorImportPlugin`. Errors surface at import time; runtime loads precompiled graphs (DM pattern).

### Action-RPG v1 scope (D1.4)

v1 targets NPC conversations, branching, conditions, commands, and subtitle-style presentation. Visual-novel extras (portraits, complex layouts, cross-file imports) are out of scope.

### Autoload facade (D1.5)

`ConversationController` is the single autoload entry point. Internal classes (`DialogueRunner`, `ConditionEvaluator`, etc.) remain testable without the scene tree.

### Testable core (D1.6)

Runner and evaluator are unit-testable without scenes. Games wire an `IDialoguePresenter` into Runtime; the Presentation subsystem supplies reference implementations (optional to adopt).

---

## v1 non-goals

| Excluded | Decision |
|----------|----------|
| Portrait images in dialogue UI | D11.4 |
| Inline text conditionals (`if` inside line text) | D8.4 |
| Cross-file `.dlg` imports | D5.5 |
| Visual dialogue editor | D19.1 |
| Custom compiled line types | D17.2 |
| Framework-owned variable store | D9.1 |
| Nested simultaneous conversations | D2.4 |

---

## Related documents

- [01-architecture-overview.md](01-architecture-overview.md) — Runtime structure
- [06-product-structure.md](06-product-structure.md) — Runtime vs Presentation subsystems
- [decisions/001-philosophy-and-scope.md](decisions/001-philosophy-and-scope.md) — ADR
- [decisions/014-product-structure-and-presentation.md](decisions/014-product-structure-and-presentation.md) — ADR
