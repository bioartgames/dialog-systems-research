# Dialogue Framework Research Summary

**Status:** Research record (pre-design)  
**Date:** 2026-07-05  
**Repository context:** Godot 4 research project containing Dialogic 2 and Dialogue Manager as reference implementations.

This document captures the results of reverse-engineering research conducted on two existing Godot dialogue plugins. It is an objective research snapshot. It does not constitute project architecture, accepted decisions, or implementation guidance.

---

# Research Scope

## What systems were analyzed

Two Godot dialogue plugins included in this repository:

| System | Location | Version (at time of research) |
|--------|----------|-------------------------------|
| **Dialogic 2** | `addons/dialogic/` | 2.0-Alpha-20 WIP (Godot 4.4+) |
| **Dialogue Manager** (Nathan Hoad) | `addons/dialogue_manager/` | 3.10.2 |

## Why they were selected

Both plugins are mature, widely used Godot dialogue solutions representing different architectural philosophies. They were selected as reference material for studying how production dialogue systems handle parsing, execution, UI, variables, branching, and game integration—without intending to adopt either plugin wholesale or modify them.

## What aspects were studied

Research focused on **runtime architecture**, including:

- Overall system structure and central orchestration
- Core runtime classes and their responsibilities
- Dialogue representation (storage format, parsing, in-memory model)
- Execution pipeline (load → parse → execute → display → advance)
- Branching, conditions, and choice handling
- Variable and state management
- Command/event implementation patterns
- Communication with game systems and UI
- Save/load support
- Extension and plugin mechanisms
- Coupling and separation of concerns
- Perceived strengths, weaknesses, and complexity sources

**Explicitly excluded or de-emphasized:**

- Editor tooling, unless it directly affects runtime architecture (e.g., compile-at-import)
- Per-file code walkthroughs
- Example assets, demo scenes, and test harnesses
- Full enumeration of every module file

## Limitations of the research

- **Static analysis only.** No runtime profiling, stress testing, or comparative benchmarks were performed.
- **Snapshot of versions.** Dialogic is marked Alpha/WIP; behavior may change between releases.
- **Partial coverage.** Dialogic contains many modules (Background, Glossary, History, StyleEditor, etc.); research prioritized modules central to the execution path (Core, Text, Choice, Variable, Condition, Jump, Save, Style, Signal, Call).
- **Single reviewer inference.** Architectural interpretations reflect one analysis pass over source code, not multi-reviewer validation.
- **No author consultation.** Conclusions are derived from code and documentation in the repository, not from plugin authors.
- **Research project, not production usage.** Neither plugin was integrated into a shipping game during this phase.
- **Prior conversation synthesis.** This document consolidates findings from an initial research session; it has not been independently re-verified line-by-line against the codebase after writing.

---

# Systems Studied

## Dialogic 2

### Overall architecture

Dialogic uses a **central autoload orchestrator** (`DialogicGameHandler`) that owns timeline execution state and dispatches work to **pluggable subsystems** discovered at startup via `DialogicIndexer` scripts in module folders. Timelines are **ordered lists of typed event resources** (`DialogicEvent` subclasses). Execution is **index-based sequential dispatch**: the handler advances `current_event_idx`, each event runs `_execute()`, and completion is signaled via `event_finished`, which triggers `handle_next_event()`.

Subsystems (Text, Choices, Variables, Expressions, Styles, Portraits, Jump, Save, etc.) are child nodes of the handler. They encapsulate domain logic and interact with scene nodes found through Godot groups (e.g., `dialogic_dialog_text`, `dialogic_choice_button`).

### Runtime philosophy

- **Event-sourced sequential virtual machine:** Dialogue is a program of discrete instructions; the handler is the VM.
- **Cooperative async:** Events `await` subsystem operations and signal completion rather than using a centralized scheduler.
- **Side effects via subsystems:** Events delegate behavior; subsystems mutate both internal state and scene tree nodes.
- **Integrated presentation default:** Starting dialogue typically loads a style layout scene unless the caller bypasses that path.

### Data model

- **On disk:** `.dtl` plain-text timeline files.
- **Load time:** Text split into lines (`DialogicTimeline.from_text()`).
- **Process time (lazy, typically at timeline start):** Lines matched against a cached registry of event types and converted to `DialogicEvent` Resource objects with exported properties.
- **Branch structure:** Python-style indentation; compiler injects synthetic `DialogicEndBranchEvent` markers when indentation decreases.
- **Not a formal AST or JSON graph:** Flat event array with index jumps for branching.
- **Additional resources:** Characters (`DialogicCharacter`), styles (`DialogicStyle`), layout layers—separate from timeline text.

### Execution model

1. `Dialogic.start(timeline)` or `start_timeline(timeline)` loads and processes the timeline.
2. `handle_event(index)` sets up the event, connects `event_finished`, calls `event.execute(dialogic)`.
3. Event `_execute()` invokes subsystems (e.g., TextEvent updates portraits, parses text, reveals in UI).
4. Player input flows through `Inputs.dialogic_action`; text events await an `advance` signal; choice events transition to `AWAITING_CHOICE` and wait for button selection.
5. On choice selection, handler jumps to `choice_index + 1` (branch body). On false condition, handler jumps to `get_end_branch_index()`.
6. End of timeline triggers `end_timeline()`, optionally playing a configured ending timeline with a clear event.

Handler exposes a **state enum** (`IDLE`, `REVEALING_TEXT`, `ANIMATING`, `AWAITING_CHOICE`, `WAITING`).

### Authoring workflow

- Timelines authored as `.dtl` text and/or through Dialogic's visual timeline editor.
- Events serialize to text via per-event `to_text()` / `from_text()` (shortcodes and Pythonic flow syntax).
- Characters, variables, and styles configured through editor tooling and ProjectSettings.
- Human-readable text format is version-control friendly.

### Parser approach

- **Runtime lazy parsing:** `DialogicTimeline.process()` converts raw lines to events when the timeline starts (or when preloaded).
- **Per-event recognition:** Each event class implements `_test_event_string()`, `from_text()`, `is_valid_event()`; unmatched lines default to `DialogicTextEvent`.
- **Shortcode parameters:** Regex-based parameter extraction for bracket syntax (e.g., `[wait time="1"]`).
- **Indentation processing:** Single pass converts nesting to flat structure with end-branch markers.

### UI architecture

- **Styles subsystem** loads composable layout scenes (`DialogicLayoutBase` + layers: textbox, portraits, choices, etc.).
- Subsystems locate UI nodes by **Godot group membership**, not by injected interfaces.
- UI nodes (`DialogicNode_DialogText`, `DialogicNode_ChoiceButton`, etc.) are passive widgets; subsystems push data and read signals.
- Style switching (including per-character styles) can reinstantiate or reconfigure layout mid-conversation.
- Flow control remains in events/subsystems, not in UI nodes.

### Save/load approach

- **`DialogicSaveState` resource:** `{ timeline path, event_index, subsystems: { name → state dict } }`.
- Each subsystem implements uniform pack/unpack: exported properties auto-serialized; `_pack_extra_state()` for scene-derived state.
- `DialogicGameHandler.get_full_state()` / `load_full_state()` aggregates subsystem state.
- **`subsystem_save`** provides slot-based file persistence (`user://dialogic/saves/`).
- Resume position is **event index**, not a line ID or graph node key.

### Extension mechanisms

- **`DialogicIndexer`** in each module folder registers events, subsystems, text effects/modifiers, layout parts, settings pages.
- New features added by creating event Resource subclasses + optional subsystem + index registration.
- Custom text effects/modifiers registered via indexer metadata pointing to methods.
- Events carry substantial editor UI metadata (fields, colors, categories) alongside runtime behavior.

### Strengths

- Modular subsystem architecture with consistent save contract.
- Clear execution state machine on the central handler.
- Typed, discoverable event commands via shortcodes.
- Human-readable `.dtl` format with editor and text authoring paths.
- Cooperative async model (`event_finished`) is straightforward to follow.
- Indentation-to-branch conversion avoids explicit end markers in authored text.
- Rich feature set for visual-novel-style presentation (portraits, styles, voice, history).

### Weaknesses

- **Tight coupling** between events, subsystems, and layout scene nodes.
- **Dual variable model** (Dialogic-owned dictionary + autoload property paths) adds conceptual overhead.
- **Style/layout system** is substantial relative to simple dialogue needs.
- **Event base class** carries significant editor-only surface area mixed with runtime code.
- Default `start()` path assumes Styles subsystem and layout presence.
- Many modules (glossary, history, backgrounds, text input) increase surface area for games that need only a subset.
- Subsystems query the scene tree directly—testing and swapping UI requires layout conventions.

---

## Dialogue Manager (Nathan Hoad)

### Overall architecture

Dialogue Manager uses a **compile-to-resource graph walker** with **externalized UI**. A `DialogueManager` autoload traverses a precompiled line graph stored in `DialogueResource`, skipping structural nodes until it yields a **`DialogueLine` DTO** (or `null` at conversation end). Presentation is entirely the responsibility of a separate "balloon" or custom UI that calls `get_next_dialogue_line()`.

There is no scene ownership by the runtime core. The autoload is an interpreter plus expression evaluator, not a presentation manager.

### Runtime philosophy

- **Compile once, walk at runtime:** Parsing cost paid at import (or explicit compile call), not during gameplay traversal.
- **Game state is authoritative:** Dialogue does not maintain its own variable store; it reads and writes game objects via expression resolution.
- **UI as thin client:** Runtime emits signals and returns DTOs; UI loops on `next_id`.
- **Data-driven control flow:** Branching encoded as `next_id`, `next_sibling_id`, `next_id_after`, and ID trail stacks—not as executable event objects.

### Data model

- **On disk:** `.dialogue` plain-text source files.
- **After import:** `.tres` `DialogueResource` containing:
  - `lines: Dictionary` — maps string IDs to compiled line dictionaries
  - `titles: Dictionary` — maps title names to line IDs (entry points)
  - `using_states`, `character_names`, `first_title`, `raw_text`
- **Compiled line types:** `dialogue`, `response`, `mutation`, `condition`, `while`, `match`, `goto`, `title`, `random`, etc.
- **Expressions:** Pre-tokenized `Array[Dictionary]` stored at compile time.
- **Not an object AST:** Flattened graph with pointer-like fields between nodes.
- **Cross-file references:** UID-based IDs (`uid@line_id`) for imports and jumps.

### Execution model

1. Caller invokes `get_next_dialogue_line(resource, key, extra_game_states)`.
2. Internal `get_line()` recursively traverses the graph from a title or line ID.
3. Structural nodes handled inline:
   - **Conditions:** evaluate → follow `next_id` or `next_sibling_id` or `next_id_after`
   - **Mutations:** `_mutate()` executes tokenized expression → continue to `next_id`
   - **Gotos:** jump to target ID; snippets push return address onto ID trail (`|return_id|...`)
   - **Random/match/concurrent:** specialized traversal rules
4. When a `TYPE_DIALOGUE` or `TYPE_RESPONSE` node is reached, runtime resolves text/character interpolations and inline conditionals, assembles attached responses, returns `DialogueLine`.
5. UI displays the line; on player action, calls `get_next_dialogue_line` with `line.next_id` or `response.next_id`.
6. `null` return emits `dialogue_ended`.

Mutations can be blocking or non-blocking; built-in `wait()` and `debug()` exist.

### Authoring workflow

- Authors write `.dialogue` text files (character-prefixed lines, `-` choices, `if`/`elif`/`else`, `=>` gotos, `do` mutations).
- Godot **EditorImportPlugin** compiles `.dialogue` → `.tres` on import (compiler version tracked).
- Titles (`~ name`) define entry points suitable for NPC conversation roots.
- Optional static line IDs for translation/save stability.
- Runtime alternative: `create_resource_from_text()` compiles in-memory (errors assert).

### Parser approach

- **Compile-time pipeline:** `DMCompiler` → `DMCompilation` builds a tree from indentation, assigns IDs, resolves links, tokenizes expressions via `DMExpressionParser`.
- **Tree flattened to dictionary** in `DMCompiledLine.to_data()`.
- **Runtime re-parsing limited:** Some inline conditionals in displayed text resolved at runtime via regex; precompiled `text_replacements` used when available.
- **Regex-heavy line classification** at compile time (`DMCompilerRegEx`).

### UI architecture

- **Fully decoupled:** Reference implementation is `DialogueManagerExampleBalloon` (CanvasLayer with `DialogueLabel`, `DialogueResponsesMenu`).
- Balloon calls `dialogue_resource.get_next_dialogue_line()`, applies results to widgets, handles input blocking.
- `DialogueLabel` implements typewriter reveal, inline mutation triggers at character indices, pause-at-punctuation.
- UI may pass itself in `extra_game_states` (e.g., for `locals` dictionary).
- `mutated` signal allows UI to hide during long-running mutations.

### Save/load approach

- **No built-in dialogue save system.**
- Persistence is the game's responsibility: game state mutated by dialogue is saved via normal game save; optional `{ resource_path, line_id }` for mid-conversation resume.
- Static line IDs (`[ID:...]`) support stable references across translation and save.

### Extension mechanisms

- **`DMDialogueProcessor`:** Override `_preprocess_line()` and `_process_line()` for custom compile hooks.
- **`using StateName`:** Injects autoloads into resolution scope per resource.
- **`game_states` array + `extra_game_states`:** Configurable state roots for expression lookup.
- **Tags on lines:** `#tag` / `#tag=value` passed through to UI for custom interpretation.
- **Custom balloon scene:** Configurable path in settings; must implement `start()`.
- **No formal command registry:** Side effects expressed as mutation expressions calling game methods.

### Strengths

- Clean separation between runtime interpreter and presentation.
- Fast runtime traversal over precompiled graph.
- No duplicate variable layer—dialogue operates on game state directly.
- Title/entry-point model maps naturally to NPC conversation roots.
- Compile-at-import catches syntax errors before runtime.
- `DialogueLine` DTO is a stable contract for any UI implementation.
- Tags provide lightweight per-line metadata without extending syntax.

### Weaknesses

- **`DialogueManager._resolve()`** is a large monolithic expression evaluator (~400+ lines) handling conditions, mutations, and interpolation.
- **C# / .NET bridge** adds parallel code paths for async C# methods.
- **Feature breadth** (match/when, while, concurrent lines, weighted random, cross-file UID jumps) may exceed needs of simpler games.
- **No first-class save/resume** for dialogue position.
- **Compile dependency:** `.dialogue` requires import step (or runtime compile) before use.
- Example balloon encodes assumptions (voice tags, auto-advance timing) that custom UI must replicate or replace.
- Direct method calls from dialogue scripts create **implicit coupling** to game API surface (no enforced facade).

---

# Cross-System Observations

## Common architectural principles

- **Central singleton orchestrator:** Both use a Godot autoload as the dialogue runtime entry point (`DialogicGameHandler`, `DialogueManager`).
- **Text as source of truth:** Both store authored dialogue as human-readable plain text, not exclusively as editor-built binary structures.
- **Separation of "what to say" from "how it looks":** Both distinguish dialogue content from presentation, though Dialogic's default path integrates presentation more deeply.
- **Entry points for conversations:** Dialogic supports labels and timeline jumps; Dialogue Manager uses `~ title` entry points explicitly.
- **Conditions gate flow:** Both evaluate conditions to skip or select branches at runtime.
- **Player advance as explicit step:** Neither auto-advances by default without configuration; user input or timers gate progression.

## Common runtime patterns

- **Graph or list traversal with skip logic:** Structural nodes (conditions, gotos) are not displayed; runtime skips until a displayable node.
- **Async/await for pacing:** Waits, text reveal, and method calls use Godot's async model.
- **Signal-based observation:** Game and UI code can listen for dialogue lifecycle events (`timeline_started`, `got_dialogue`, `dialogue_ended`, `mutated`, etc.).
- **Autoload integration:** Both resolve variables and invoke behavior against game autoloads and scene nodes.
- **Rich text display:** Both target `RichTextLabel`-based rendering with BBCode or marker syntax.

## Common abstractions

- **Line / event as atomic step:** The unit of authorship maps to a unit of execution or display.
- **Choice as branch entry:** Selecting a choice redirects execution into a branch body.
- **Character + text pairing:** Speaker identification paired with utterance text.
- **Expression evaluation for conditions and interpolation:** Both substitute variables and evaluate boolean/numeric expressions, though engines differ.

## Recurring tradeoffs

- **Integrated vs decoupled UI:** Tighter integration speeds default setup; decoupling increases flexibility.
- **Compile-time vs runtime parsing:** Compile-time catches errors early; runtime parsing simplifies tooling.
- **Owned variables vs game state:** Owned variables simplify dialogue-only logic; game state avoids duplication.
- **Typed commands vs free-form mutations:** Typed commands are discoverable; mutations are flexible but less constrained.
- **Feature breadth vs maintenance cost:** VN-oriented features add capability and complexity.

## Shared design philosophies

- **Extend via registration:** Dialogic uses indexers; Dialogue Manager uses processor hooks and configurable state roots—both favor plugin-style extension over modifying core.
- **Author-friendly text syntax:** Both prioritize writable dialogue scripts over purely visual authoring for the underlying format.
- **Godot-native integration:** Both lean on Resources, autoloads, signals, groups, and Expression/token evaluation rather than external runtimes.

---

# Unique Ideas

## Dialogic 2

### Subsystem plugin architecture with uniform save contract

**What it is:** Feature modules register subsystems via `DialogicIndexer`; each subsystem inherits `DialogicSubsystem` with `_clear_state`, `_load_state`, and automatic export-based serialization.

**Why interesting:** Creates a repeatable pattern for adding features that participate in save/load and lifecycle without modifying the core handler.

**Problems addressed:** Feature modularity, save-state aggregation, pause/resume propagation.

**Possible drawbacks:** Subsystem count grows quickly; cross-subsystem dependencies emerge; scene-coupled subsystems resist isolated testing.

### Synthetic End Branch events from indentation

**What it is:** `DialogicTimeline.process()` injects `DialogicEndBranchEvent` when indentation decreases, converting nested blocks to flat index jumps.

**Why interesting:** Authors write Python-style blocks without explicit end markers; runtime uses simple index arithmetic.

**Problems addressed:** Readable branching syntax; flat event array execution.

**Possible drawbacks:** Implicit structure can confuse debugging; error in indentation corrupts branch boundaries silently.

### Event completion chaining (`event_finished` → `handle_next_event`)

**What it is:** Each event signals completion; handler connects/disconnects this signal per event.

**Why interesting:** Minimal scheduler; events freely `await` without central async state machine beyond handler `States`.

**Problems addressed:** Cooperative multitasking for text reveal, waits, and method calls.

**Possible drawbacks:** Signal connection management on rapid event transitions; `_cleanup_previous_event()` must disconnect properly.

### Style/layout composition system

**What it is:** `DialogicStyle` resources compose layout layers (textbox, portraits, choices) with inheritance and overrides; Styles subsystem instantiates and hot-swaps layouts.

**Why interesting:** Supports multiple visual themes and character-specific layouts without duplicating dialogue logic.

**Problems addressed:** VN-style presentation variety.

**Possible drawbacks:** Large subsystem; reinstantiating layouts on style change is expensive; tight binding between style and node structure.

### Dual-path game integration (Call events + Signal events)

**What it is:** `DialogicCallEvent` awaits autoload method calls; `DialogicSignalEvent` emits `Dialogic.signal_event` for game listeners.

**Why interesting:** Supports both synchronous (awaitable) and fire-and-forget integration patterns explicitly.

**Problems addressed:** Cutscenes/game logic triggered from dialogue with different coupling levels.

**Possible drawbacks:** Two patterns to learn; Call events require stringly method names and autoload paths.

---

## Dialogue Manager

### Compile-to-ID graph with import pipeline

**What it is:** `.dialogue` text compiles at editor import into `DialogueResource.lines` dictionary; compiler version invalidates stale imports.

**Why interesting:** Runtime traversal is dictionary lookup and ID following—no lexing during gameplay.

**Problems addressed:** Runtime performance; early error detection; reproducible compiled artifacts.

**Possible drawbacks:** Import step required; compiler version bumps force reimport; runtime `create_resource_from_text()` duplicates pipeline.

### ID trail return stack for snippet gotos

**What it is:** Goto snippets push return addresses onto a `|return_id|...` trail appended to `next_id`; END pops the stack.

**Why interesting:** Implements callable dialogue subroutines without a runtime call stack object.

**Problems addressed:** Reusable dialogue snippets; return after embedded conversation block.

**Possible drawbacks:** String-encoded stack is opaque; debugging jump chains requires understanding trail format.

### Game-state-only variables (no dialogue variable store)

**What it is:** `_get_state_value` / `_set_state_value` search `extra_game_states`, scene, autoload dictionary, and configured shortcuts—no parallel variable namespace.

**Why interesting:** Single source of truth; saved game state equals dialogue-relevant state.

**Problems addressed:** Variable duplication; save/load consistency.

**Possible drawbacks:** Dialogue scripts tightly coupled to game object API; refactors break dialogue; name collision warnings needed.

### DialogueLine as presentation-neutral DTO

**What it is:** Runtime returns `DialogueLine` with resolved text, responses, tags, speeds, inline mutations—UI consumes without knowing graph structure.

**Why interesting:** Any renderer (2D balloon, 3D subtitle, action-RPG popup) can implement against one contract.

**Problems addressed:** UI replacement; testability of presentation separately from traversal.

**Possible drawbacks:** DTO may carry compiler internals (`text_replacements`); some resolution still happens at DTO creation time.

### Pre-tokenized expressions at compile time

**What it is:** Conditions and mutations stored as token arrays in compiled line data; runtime `_resolve()` interprets tokens.

**Why interesting:** Avoids re-lexing on every condition check during traversal.

**Problems addressed:** Runtime cost of repeated parsing in branching-heavy dialogue.

**Possible drawbacks:** Large compiled resources; token format is internal and complex; evaluator still monolithic at runtime.

### `mutated` signal as integration seam

**What it is:** Signal emitted before/during mutation execution; example balloon hides UI on non-inline mutations.

**Why interesting:** UI can react to game-state-changing steps without parsing mutation content.

**Problems addressed:** Hiding dialogue during cutscenes/shops; decoupling presentation from side effects.

**Possible drawbacks:** Timing semantics (before vs after mutation) require careful reading; easy to miss for custom UI.

---

# Architectural Tradeoffs

## Flexibility vs simplicity

| Dimension | Dialogic tendency | Dialogue Manager tendency |
|-----------|-------------------|---------------------------|
| Feature surface | Broad (VN modules) | Broad (language features) |
| Getting started | Higher (layout/styles) | Lower (balloon + `.dialogue`) |
| Custom game profile | Disable modules; still carry weight | Subset syntax informally |

**Observation:** Both skew toward maximum capability. Simpler games inherit complexity they may not use.

## Compile time vs runtime processing

| Approach | Dialogic | Dialogue Manager |
|----------|----------|------------------|
| When parse happens | At timeline start (`process()`) | At editor import (primary) |
| Runtime cost | Event instantiation per start | Graph walk only |
| Error detection | At conversation start | At import (primary) |

**Observation:** Dialogic defers cost to conversation start; Dialogue Manager front-loads to build time.

## Data-driven vs code-driven approaches

- **Dialogic:** Data-driven via event Resources; behavior in `_execute()` code per event type.
- **Dialogue Manager:** Data-driven graph; behavior split between compile structure and `_resolve()` / `_mutate()` code.

**Observation:** Both hybridize—structure in data, semantics in code—but Dialogic distributes semantics across many event classes; Dialogue Manager concentrates semantics in the autoload interpreter.

## Editor complexity vs runtime simplicity

- **Dialogic:** Substantial editor investment; runtime still complex due to subsystems and layout.
- **Dialogue Manager:** Editor for syntax highlighting, compilation, testing; runtime interpreter is conceptually simpler but `_resolve()` is dense.

**Observation:** Editor tooling does not necessarily yield a simpler runtime.

## Extensibility vs maintainability

- **Dialogic:** Extension via new events/subsystems is structured; total module count affects maintainability.
- **Dialogue Manager:** Extension via mutations and processor hooks is flexible; unconstrained mutations reduce maintainability.

## Integrated UI vs separated UI

- **Dialogic integrated:** Faster default, harder to replace without understanding groups and layouts.
- **Dialogue Manager separated:** More upfront UI work, cleaner boundary.

## Owned variables vs game state variables

- **Dialogic owned + autoload paths:** Dialogue-specific flags possible without game code; dual model.
- **Dialogue Manager game-only:** No duplication; dialogue depends on game API stability.

## Typed commands vs expression mutations

- **Dialogic shortcode events:** Named, discoverable, editor-documented commands.
- **Dialogue Manager mutations:** Arbitrary expressions calling any reachable method.

## Save/resume complexity

- **Dialogic:** Built-in multi-subsystem save; resume via event index.
- **Dialogue Manager:** No built-in; game must design snapshot format.

---

# Important Observations

1. **Both systems use a single autoload as the runtime hub.** All dialogue operations funnel through one singleton, simplifying discovery but creating a god-object tendency (especially Dialogue Manager's `_resolve()`).

2. **Branching is index- or ID-based, not recursive tree walking at display time.** Structural nodes are skipped by pointer advancement, not by interpreting nesting at render time.

3. **Text reveal is UI-adjacent but flow-gating.** Both block progression until text is fully revealed or skipped; this is a dialogue state concern shared by runtime and UI.

4. **Choice selection redirects control flow.** Neither system treats choices as data-only; selection commits to a branch path.

5. **Condition evaluation happens at traversal time, not at compile time** (except Dialogue Manager pre-tokenizes, not pre-evaluates). Branch outcomes depend on runtime game state.

6. **Dialogic's event index and Dialogue Manager's line ID are incompatible resume coordinates.** Migrating between models would require a mapping strategy.

7. **Dialogic subsystems directly query the scene tree.** There is no abstract `IDialogueView` interface—convention via groups.

8. **Dialogue Manager's compile pipeline produces immutable runtime data.** Mutations mutate game state, not the `DialogueResource`.

9. **Both support rich inline text logic** (Dialogic `[if cond]text[/else]` modifiers; Dialogue Manager inline conditionals in resolved line data)—display text can depend on runtime conditions beyond branch-level `if`.

10. **Async method calls from dialogue are first-class in both systems** (Dialogic Call events with `await`; Dialogue Manager mutation method calls with C# Task bridge).

11. **Localization is handled differently:** Dialogic translation IDs on events; Dialogue Manager static line IDs and CSV/PO modes with `translation_key`.

12. **Dialogic's `States` enum exposes dialogue phase explicitly;** Dialogue Manager infers phase from UI state (`is_waiting_for_input`, `dialogue_label.is_typing`).

13. **Neither system defines a bounded game API facade.** Integration is open—autoloads, method calls, signals—placing coupling discipline on the game team.

14. **Dialogic carries editor metadata in runtime event classes** (`@tool`, `editor_list`, `build_event_editor`), increasing runtime script surface even if unused in export builds.

15. **Dialogue Manager's `extra_game_states` enables per-conversation scope** (NPC instance, shop context) without global state pollution—a lightweight contextual binding mechanism.

---

# Open Questions Raised During Research

## 1. What resume granularity is required for mid-conversation save?

**Why it matters:** Event index (Dialogic) vs line ID (Dialogue Manager) vs game-state-only resume imply different save snapshot designs.

**Known:** Both can resume if position + game state are stored; Dialogic has built-in aggregation; Dialogue Manager defers to game.

**Uncertain:** Whether mid-line (during typewriter), mid-mutation, or mid-command resume is needed for the target game; whether resume should restore UI presentation state or only logical position.

## 2. How much expression language capability is needed?

**Why it matters:** Full expression evaluators (Dialogue Manager) vs Godot Expression subset (Dialogic) vs dedicated condition DSL affect security, debuggability, and coupling.

**Known:** Both support comparisons, boolean logic, property access, method calls to varying degrees.

**Uncertain:** Whether arbitrary method calls from dialogue scripts are desirable or should be restricted to a command registry for the target game.

## 3. Should dialogue own any state separate from game state?

**Why it matters:** Dialogic variables vs Dialogue Manager's game-only model affects save/load and authoring.

**Known:** Dialogic `var_storage` can hold dialogue-only flags; Dialogue Manager uses balloon `locals` for ephemeral UI scope.

**Uncertain:** Whether dialogue-only ephemeral state (e.g., "which choice index was hovered") ever needs persistence.

## 4. Where should compile-time validation live?

**Why it matters:** Import-time errors (Dialogue Manager) vs start-time errors (Dialogic) affect developer workflow and CI integration.

**Known:** Dialogue Manager compiler version is tracked; Dialogic validates on `process()`.

**Uncertain:** Whether a custom system would use Godot import, external CLI, or runtime-only parsing for initial development without an editor.

## 5. How should 3D action-RPG presentation differ from VN assumptions?

**Why it matters:** Both plugins assume 2D CanvasLayer-style presentation; 3D portraits, world-space bubbles, and combat-gated dialogue may need different UI boundaries.

**Known:** Dialogue Manager's separated UI makes custom 3D presenters feasible; Dialogic's layout system is 2D-oriented.

**Uncertain:** Whether dialogue during combat, while moving, or in shop mode requires pausing game simulation—a game design question with architectural implications.

## 6. What is the appropriate coupling model for quest/inventory/shop integration?

**Why it matters:** Mutations calling game methods directly vs signal/command indirection affects refactor safety.

**Known:** Both allow direct calls; Dialogic adds Signal events; Dialogue Manager emits `mutated`.

**Uncertain:** Whether a facade/`GameContext` pattern is warranted or over-engineering for project scale.

## 7. How should shop and cutscene interactions interact with dialogue flow?

**Why it matters:** Shops and cutscenes may need to preempt, pause, or terminate dialogue; neither plugin models "game mode" explicitly.

**Known:** Dialogue Manager example hides balloon on mutation; Dialogic Call events can `await` cutscene methods.

**Uncertain:** Whether dialogue should nest inside cutscenes, run parallel, or hand off control entirely.

## 8. What localization workflow will the project use?

**Why it matters:** CSV vs PO vs per-line IDs affect compiler and runtime design.

**Known:** Both support Godot TranslationServer; mechanisms differ.

**Uncertain:** Project localization pipeline not defined during research phase.

## 9. Is compile-at-import acceptable for iteration speed during early development?

**Why it matters:** Dialogue Manager reimport cycle vs Dialogic text-edit-and-run affects iteration.

**Known:** Dialogue Manager supports runtime `create_resource_from_text()` as alternative.

**Uncertain:** Team preference for authoring workflow without visual editor.

## 10. How testable must the runtime be without Godot scene tree?

**Why it matters:** Dialogic subsystem-scene coupling complicates unit testing; Dialogue Manager runner is more isolated from UI.

**Known:** Dialogue Manager graph walker can be invoked with mock `extra_game_states`.

**Uncertain:** Target test strategy for custom framework not defined.

---

# Confidence Assessment

| Conclusion | Confidence | Rationale |
|------------|------------|-----------|
| Dialogic uses index-based event dispatch via `DialogicGameHandler.handle_event()` | **High** | Directly observed in `DialogicGameHandler.gd` |
| Dialogic subsystems registered via `DialogicIndexer` | **High** | `_collect_subsystems()` and `index_class.gd` |
| Dialogic timelines parse lazily in `DialogicTimeline.process()` | **High** | `timeline.gd` implementation |
| Dialogic save uses `DialogicSaveState` with per-subsystem dictionaries | **High** | `save_state.gd`, `get_full_state()`, `subsystem_save.gd` |
| Dialogic UI located via Godot groups | **High** | Observed in `subsystem_choices.gd`, `node_dialog_text.gd` |
| Dialogue Manager compiles at import to `DialogueResource` | **High** | `import_plugin.gd`, `DMCompiler` |
| Dialogue Manager runtime traverses line graph by ID | **High** | `dialogue_manager.gd` `get_line()` |
| Dialogue Manager has no built-in save system | **High** | No save subsystem; resume left to game |
| Dialogue Manager uses pre-tokenized expressions | **High** | `compiled_line.gd`, `expression_parser.gd` |
| Dialogue Manager UI is external to core runtime | **High** | `example_balloon.gd` pattern; core returns DTOs |
| Dialogic condition evaluation uses Godot `Expression` | **High** | `subsystem_expression.gd` |
| Dialogue Manager condition evaluation uses custom token resolver | **High** | `_resolve()` in `dialogue_manager.gd` |
| Dialogic is more integrated with default UI | **Medium** | `start()` loads style by default; bypass exists via `start_timeline()` |
| Dialogic carries significant editor-only code in runtime classes | **Medium** | `@tool` on events; large editor sections in `event.gd`; export impact not measured |
| Dialogue Manager `_resolve()` is a maintainability hotspot | **Medium** | Code size observed; "hotspot" is interpretive |
| Neither system enforces a game API boundary | **High** | Both allow direct autoload/method access |
| Dialogic dual variable model causes author confusion | **Medium** | Architecture confirmed; confusion severity inferred |
| Dialogue Manager C# bridge adds meaningful complexity | **Medium** | Bridge code present; impact depends on GDScript-only vs mixed project |
| Compile-at-import is faster at runtime than lazy parse | **Medium** | Logical inference; not benchmarked |
| 50% code reduction targets identified in research are accurate | **Low** | Rough engineering estimates from module inventory, not measured LOC |

---

# Facts vs Interpretations vs Recommendations

## Facts

(Observations directly supported by analyzed source code and structure in this repository.)

- Dialogic 2 version in repo: `2.0-Alpha-20 WIP (Godot 4.4+)`.
- Dialogue Manager version in repo: `3.10.2`.
- Dialogic central autoload class is `DialogicGameHandler`; it maintains `current_timeline`, `current_event_idx`, and a `States` enum.
- Dialogic discovers subsystems through `DialogicIndexer` scripts and `_collect_subsystems()`.
- Dialogic timelines are stored as `.dtl` text and converted to `DialogicEvent` arrays in `DialogicTimeline.process()`.
- Dialogic events complete via `event_finished` signal connected to `handle_next_event()`.
- Dialogic provides `DialogicSaveState` and `get_full_state()` / `load_full_state()` aggregating subsystem state.
- Dialogic choice selection calls `handle_event(choice_index + 1)` after hiding choice UI.
- Dialogic false conditions set `current_event_idx = get_end_branch_index()`.
- Dialogic conditions evaluated via `Expression` after `{variable}` substitution in `subsystem_expression.gd`.
- Dialogic variables stored in `subsystem_variables.var_storage` with ProjectSettings defaults; autoload paths also supported.
- Dialogic default `start()` loads a style layout via Styles subsystem.
- Dialogue Manager central autoload is `DialogueManager`, registered as engine singleton.
- Dialogue Manager compiles `.dialogue` files via `DMImportPlugin` using `DMCompiler.compile_string()`.
- Dialogue Manager stores compiled data in `DialogueResource.lines` (Dictionary keyed by line ID).
- Dialogue Manager runtime entry point for traversal is `get_next_dialogue_line()` / `get_line()`.
- Dialogue Manager returns `DialogueLine` objects for display; returns `null` at conversation end.
- Dialogue Manager executes mutations via `_mutate()` calling `_resolve()` on token arrays.
- Dialogue Manager resolves variables by searching `extra_game_states`, current scene, and autoload dictionary—no dedicated dialogue variable resource.
- Dialogue Manager provides reference UI in `example_balloon.gd` using `DialogueLabel` and `DialogueResponsesMenu`.
- Dialogue Manager emits `got_dialogue`, `dialogue_started`, `dialogue_ended`, and `mutated` signals.

## Interpretations

(Conclusions inferred from research; not necessarily stated by plugin authors.)

- Dialogic's architecture resembles an event-driven VM with subsystem side-effects rather than a pure MVC separation.
- Dialogue Manager's architecture resembles a compiled graph interpreter with a presentation-neutral boundary.
- Dialogic's default integration path optimizes visual-novel workflows where layout, portraits, and styles are first-class.
- Dialogue Manager's default integration path optimizes projects that want dialogue logic separate from any specific UI.
- Dialogic's subsystem model scales feature addition well but tends toward cross-subsystem coupling over time.
- Dialogue Manager's monolithic `_resolve()` concentrates expression semantics, aiding traceability in one file but hindering modular evolution.
- Both systems would require significant subsetting to match a minimal action-RPG dialogue profile.
- Dialogic event index resume may not map cleanly to Dialogue Manager line ID resume without an adapter layer.
- Open method/mutation access in both systems places API stability responsibility on game code, not dialogue tooling.
- Dialogic's indentation-to-End-Branch transformation is a central enabler of its flat execution model.
- Dialogue Manager's ID trail mechanism implements subroutine-like dialogue without explicit stack objects in the data model.

## Recommendations

(Emerged during research discussions. **Not accepted.** **Not project decisions.** Recorded for traceability only.)

- For a single-player 3D action RPG, Dialogue Manager's compile + DTO + game-state ownership model may fit better as a structural skeleton than Dialogic's integrated VN stack. *(Research discussion inference; not validated by implementation.)*
- Dialogic's subsystem modularity, explicit state machine, and typed command pattern may be worth adopting in simplified form. *(Suggestion from comparative analysis.)*
- Avoid Dialogic's layout/style inheritance engine if the game needs only one dialogue HUD. *(Complexity reduction suggestion.)*
- Avoid Dialogue Manager's full expression language if the game needs only flags, item checks, and simple comparisons. *(Complexity reduction suggestion.)*
- A hypothetical custom system might combine: compile-to-graph (Dialogue Manager), subsystem-style modules (Dialogic), game-owned state (Dialogue Manager), typed command registry (Dialogic-inspired), and explicit `GameContext` facade (not present in either plugin). *(Exploratory design sketch from research session—not an approved architecture.)*
- Initial research suggested ~30–40% surface area relative to either full plugin might suffice for a purpose-built action-RPG dialogue layer. *(Rough estimate; not measured.)*
- Research session identified candidate removal targets in each plugin (Dialogic: style editor, history, glossary, layered portraits; Dialogue Manager: C# bridge, match/when, concurrent lines) as complexity reduction examples. *(Illustrative, not a project scope decision.)*

---

# Research Summary

This research phase reverse-engineered two Godot dialogue plugins—**Dialogic 2** and **Dialogue Manager**—to understand how production dialogue frameworks structure runtime execution, data representation, parsing, UI boundaries, variables, branching, and persistence.

**Dialogic 2** implements a modular autoload orchestrator executing ordered **event resources** along a timeline index. Feature areas are packaged as **subsystems** with a shared save contract. Branching uses indentation processed into flat events with synthetic end markers. Presentation is **integrated by default** through a style/layout system that instantiates scene nodes located by Godot groups. Variables can live in Dialogic storage or autoload paths. Save/load is **first-class**, keyed to timeline path and event index. The system is feature-rich and VN-oriented, with coupling between events, subsystems, and layout scenes as a notable structural characteristic.

**Dialogue Manager** implements a **compile-to-resource graph walker** that traverses precompiled line dictionaries at runtime, skipping structural nodes until producing **DialogueLine DTOs** for external UI. Parsing occurs primarily at **editor import**. Variables are not owned by dialogue—all reads and writes target **game state** via a token-based expression evaluator concentrated in the autoload. Branching uses linked node IDs, sibling chains, and an ID trail for snippet returns. Save/load for dialogue position is **not provided**. UI is **decoupled** by design; the example balloon demonstrates the contract. The system is flexible and script-like, with a large expression evaluator as a central complexity concentration.

**Cross-cutting findings:** Both systems center on a singleton runtime hub, use human-readable text as authoring input, gate progression on text reveal and player input, evaluate conditions at traversal time, and integrate with game code through autoloads, method calls, and signals—without enforcing a bounded game API. They differ primarily on **when parsing happens**, **who owns variables**, **how tightly UI is bound**, and **how commands are expressed** (typed events vs mutations).

**Tradeoffs documented** include flexibility vs simplicity, compile-time vs runtime parsing, integrated vs separated UI, owned vs game-state variables, and typed commands vs free-form mutations.

**Open questions** remain regarding resume granularity, expression language scope, shop/cutscene interaction with dialogue flow, localization pipeline, 3D presentation requirements, and testability expectations—none resolved during this research phase.

This document preserves the pre-design understanding of dialogue framework architecture as observed in these two reference systems. It intentionally does **not** specify a final design for a custom framework. Subsequent architecture work may reference these findings, challenge them with further evidence, or resolve open questions through project-specific decisions.
