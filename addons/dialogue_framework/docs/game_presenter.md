# Presenter Contract and Presentation Product Guide

The Dialogue Framework product has two subsystems: **Runtime** (headless execution) and **Presentation** (dialogue UI technology).

**Architecture:** [Presentation Product Specification v1](../../../../docs/architecture/dialogue/07-presentation-product-spec.md) · [ADR-014](../../../../docs/architecture/dialogue/decisions/014-product-structure-and-presentation.md) · [ADR-015–019](../../../../docs/architecture/dialogue/decisions/015-presentation-product-concepts.md) · [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md)

**Runtime** ships the **`IDialoguePresenter` interface** only (`runtime/i_dialogue_presenter.gd`). **Presentation** (`presentation/`) provides layout scenes, Theme/Policy/Input resources, and reference implementations. **Games** wire a presenter into `ConversationController.start()` and handle orchestration only.

---

## Presentation product concepts (editor-first)

Presentation exposes four composable concepts. Customize through **scene + resources + Inspector**, not presenter scripts.

| Concept | Owns | Customize by |
|---------|------|--------------|
| **Layout** | Dialogue HUD structure (speaker, line, choices, panels) | Duplicate a reference layout scene; edit in Godot scene editor |
| **Theme** | Visual identity (colors, fonts, choice chrome) | Duplicate Theme resource; assign on presenter |
| **Policy** | Behavior (typewriter, tags, overflow, reduced motion) | Duplicate Policy resource; assign on presenter |
| **Input** | Dialogue UX key/action mapping | Duplicate Input resource; assign on layout |

**Layout is the primary product surface.** Duplicate a dialogue HUD layout scene. The presenter inside is pre-wired Runtime integration infrastructure—not the normal customization target.

See [reference-content-v1.md](../presentation/reference-content-v1.md) for v1 reference assets and [07-presentation-product-spec.md](../../../../docs/architecture/dialogue/07-presentation-product-spec.md) for the full product model.

---

## Runtime contract (`IDialoguePresenter`)

The interface exposes exactly two methods:

| Method | When called | Responsibility |
|--------|-------------|----------------|
| `present(step: ConversationStep)` | After `ConversationController` emits `step_ready(step)` | Render the current `LINE` or `CHOICES` step |
| `dismiss()` | On `cancel()`, before `COMMAND` execution when a line is visible, and when the conversation ends | Hide or clear dialogue UI |

**Not part of the contract:**

- No `on_choice` callback — Presentation wires choice UI to `ConversationController.choose(index)` (D11.2).
- The presenter must **not** call `DialogueRunner`, read `CompiledDialogue`, or advance the conversation directly.
- The presenter **must** call `ConversationController.notify_presentation_finished()` when a `LINE` step is ready for the next input (see below).

**Test double:** `tests/helpers/mock_dialogue_presenter.gd` — minimal Runtime integration stub (not production UI).

---

## Presentation subsystem responsibilities

Owned by `presentation/` (ADR-014, ADR-015). Not owned by Runtime or Ui React.

| Area | Presentation owns |
|------|-------------------|
| **Layouts** | Dialogue HUD layout scenes (primary consumer surface) |
| **Theme** | Visual identity resources |
| **Policy** | Behavior and timing resources (typewriter, tags, overflow, reduced motion) |
| **Input** | Dialogue UX input mapping resources |
| **Implementations** | Reference `IDialoguePresenter` (`DialoguePresenter`) and per-region slot scripts |
| **Accessibility** | Dialogue a11y behavior (Policy) and visual variants (Theme) — ADR-017 |
| **Default dialogue input** | Skip, advance, choice navigation/confirm — ADR-016 |
| **Ui React** | Optional per-control composition within layouts — not a separate path |

Presentation **must not** require Ui React. Dialogue Framework and Runtime **must not** depend on Ui React.

**Unsupported customization:** subclassing reference presenters to change look, timing, choice position, or anchors. Use Layout, Theme, Policy, and Input instead (ADR-018).

---

## v1 presentation constraints (D11.4)

Subtitle-style dialogue for 3D action RPG:

- **Subtitle text + speaker name only** — no portrait images in v1.
- **Do not use `#portrait`** — the tag is rejected at compile time.
- **`ConversationStep` has no portrait field** — do not add one in presenters.

Speaker display name:

```gdscript
tr(step.speaker_id, "speakers")
```

No speaker registry ships with the framework; use Godot translation CSV/domain `speakers` (D13.3).

---

## Game integration checklist

### Minimum setup

1. Implement `GameContext` for game state.
2. Instance a **native reference layout scene** in your game (see [reference-content-v1.md](../presentation/reference-content-v1.md)).
3. **Pause or restrict player control** when starting a conversation.
4. Pass the layout's presenter to `ConversationController.start(compiled, entry, context, presenter)`.
5. Restore player control on `conversation_ended` or `conversation_cancelled`.

### Recommended setup (editor-first)

1. Duplicate the closest **layout variant** for your dialogue style.
2. Duplicate **Theme** and **Policy** resources; assign them on the presenter node in the Inspector.
3. Optionally duplicate **Input** to rebind dialogue keys.
4. Adjust panel positions in the scene editor if needed.

### Presentation input (ADR-016)

Reference layouts ship **default dialogue UX input** (skip typewriter, advance line, navigate/confirm choices). For the common case:

- **Do not** reimplement skip, advance, or choice navigation in game orchestrator scripts.
- **Do** override or disable default presentation input only when other UI layers compete for the same actions.

| Owner | Responsibility |
|-------|----------------|
| **Presentation (default)** | Dialogue UX input during active conversations |
| **Game** | Conversation start/stop, player pause, optional input override |

### Accessibility (ADR-017)

- Apply player **reduced motion** by swapping to an accessibility **Policy** resource.
- Apply **high contrast** or **large text** by swapping **Theme** variants.
- Game selects resources from settings — it does not implement typewriter-skip or contrast logic.

### Escape hatches (scripting required)

| Need | Approach |
|------|----------|
| World-space / 3D / custom widget dialogue | Custom `IDialoguePresenter` |
| Input arbitration with competing UI | Disable default presentation input; route from game |
| Layout outside slot convention | Custom layout + custom presenter |

---

## LINE step presentation (D11.5, D11.6)

For `ConversationStepKind.LINE` — **Presentation Policy**:

1. Resolve speaker label with `tr(step.speaker_id, "speakers")`.
2. Display `step.text` with BBCode enabled (D11.6).
3. Run a **typewriter / reveal effect** per Policy.
4. When the line is fully revealed **and** any tag-driven timers/audio complete, call:

   ```gdscript
   ConversationController.notify_presentation_finished()
   ```

5. Default presentation input or the player triggers `ConversationController.advance()` when ready.

`WAIT` and `COMMAND` steps are handled by the controller — the presenter is not called for those step kinds.

---

## CHOICES step presentation (D6.9)

For `ConversationStepKind.CHOICES`:

1. Present `step.options` (already filtered by conditions at step-build time).
2. Display each option's `text` field per Theme.
3. On player selection, call `ConversationController.choose(index)` with the option's `index` field — **not** an `on_choice` presenter callback.

Default presentation input handles keyboard navigation unless disabled by the game.

---

## Tag handling (D4.8, D11.7, D13.5)

Tags are compiled onto `ConversationStep.tags` as `PackedStringArray` entries (`#voice=path`, `#time=auto`, `#time=1.5`, etc.).

| Tag | Presentation responsibility (Policy) |
|-----|--------------------------------------|
| `#voice=<path>` | Play voice audio at `res://` path. Call `notify_presentation_finished()` when playback completes (D11.7). |
| `#time=auto` | After typewriter completes, timer from visible text length (BBCode stripped), clamped per Policy (D13.5). |
| `#time=<N>` | After typewriter completes, wait `N` seconds, then `notify_presentation_finished()`. |

**Runtime** stores tags on the step only. **Presentation Policy** defines interpretation.

---

## Text overflow (ADR-018)

Policy defines overflow behavior for long lines: **grow**, **clamp**, or **scroll**. Combine with layout sizing in the scene editor. No game scripts required for standard overflow modes.

---

## What Runtime does not provide

- Dialogue HUD layout scenes
- Theme, Policy, or Input resources
- Built-in typewriter, voice, or `#time` logic
- Choice UI widgets or default dialogue UX input
- Dialogue accessibility behavior

---

## Related architecture

- [07-presentation-product-spec.md](../../../../docs/architecture/dialogue/07-presentation-product-spec.md) — Frozen product specification v1
- [06-product-structure.md](../../../../docs/architecture/dialogue/06-product-structure.md) — Subsystems and dependencies
- [02-authoring-format.md](../../../../docs/architecture/dialogue/02-authoring-format.md) — Authoring syntax and tags
- [01-architecture-overview.md](../../../../docs/architecture/dialogue/01-architecture-overview.md) — Controller API and signals
- [presentation/README.md](../presentation/README.md) — Presentation folder and reference assets
