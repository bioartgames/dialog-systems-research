# Integration Kit Adoption Guide

Optional editor-first game-boundary surfaces for the Dialogue Framework (**ADR-024**). Adoption is **not required** — custom `GameContext`, manual `CommandRegistry` registration, and bespoke orchestration remain valid.

**Package:** [`integration/`](../integration/) · **Architecture:** [ADR-024](../../../docs/architecture/dialogue/decisions/024-optional-game-integration-kit.md) · [06-product-structure.md](../../../docs/architecture/dialogue/06-product-structure.md)

---

## When to use the kit vs custom wiring

| Prefer the **Integration kit** when… | Prefer **custom wiring** when… |
|--------------------------------------|--------------------------------|
| You want Inspector exports for start/context/commands | You already have a save-backed `GameContext` and boot code |
| Prototyping / demos / greybox dialogue | You need per-NPC contexts, complex async game modes, or custom orchestrators |
| Common `@commands` map cleanly to context methods + Callables | Command registration is highly dynamic or already centralized |

You can mix: e.g. kit `ConversationStarter` + your own `GameContext` via `set_context()`.

**Reference demo:** `game/dialogue_demo/` uses the kit for start/context/commands (`ConversationStarter` + `CommandBridge` + `CompiledDialogueLoader`) while keeping the panel, smoke harness, locale toggle, and JSON catalogs demo-owned — see ADR-024 D30.11.

---

## Package invariants (do not weaken)

1. **Runtime** must not import Integration or Presentation.
2. **Integration** may depend on Runtime and `data/` only — **not** `presentation/` or Ui React.
3. Presenters are wired by **`NodePath` / `IDialoguePresenter`** in the game scene.
4. Kit surfaces do **not** own translation catalogs, locale policy, or authoritative save data (D1.1, D28.7).

---

## Minimal adoption path

### 1. Presenter in the scene

Add a Presentation reference HUD (or any `IDialoguePresenter`) to your scene. Note its node path relative to the starter (e.g. `DialogueHUD/Presenter`).

### 2. ResourceGameContext (or custom context)

Create a `ResourceGameContext` `.tres` (or inline sub-resource) and fill Inspector dictionaries as needed for the conversation. This is **session / config scratch**, not your save file.

Or skip the Resource and call `starter.set_context(my_game_context)` with a custom `GameContext`.

### 3. CommandBridge (optional)

Create a `CommandBridge` Resource. Enable the `@commands` you need. For game-mode hooks (`open_shop`, `cutscene`, `camera`, `anim`), assign Callables on the starter from code:

```gdscript
starter.on_open_shop = _on_open_shop
starter.on_cutscene = _on_cutscene
# camera / anim similarly
```

Still declare game command names in a **`CommandManifest`** for compile validation — see [game_command_integration.md](game_command_integration.md).

### 4. ConversationStarter

Add a `ConversationStarter` Node and set exports:

| Export | Purpose |
|--------|---------|
| `compiled_dialogue` and/or `dialogue_path` | `CompiledDialogue` resource, or path to imported `.dlg` / `.tres` |
| `entry_title` | Title label (default `start`) |
| `presenter_path` | Path to an `IDialoguePresenter` |
| `context_resource` | Kit `ResourceGameContext` (unless using `set_context`) |
| `command_bridge` | Optional bridge Resource |
| `register_commands_on_ready` | Register bridge on `_ready` (default true) |

Start / cancel:

```gdscript
starter.start_conversation()
starter.cancel_conversation()
```

These call existing `ConversationController.start` / `cancel` only.

### 5. Load helper (optional)

`CompiledDialogueLoader.load_compiled(path)` returns `{ compiled, source, errors }` for imported `.dlg` or saved `CompiledDialogue` paths. The starter uses this when `dialogue_path` is set and `compiled_dialogue` is empty.

---

## Localization — primary story (Godot-native)

Per **ADR-020 / ADR-022 / ADR-024 D30.8**, the game / Godot project owns catalogs and locale selection. Runtime **resolves** identities; it never registers catalogs.

### Recommended workflow

1. After compile, use each surface’s **`translation_key`** (LINE / CHOICE) as the lookup key in your translation tables ([ADR-021](../../../docs/architecture/dialogue/decisions/021-localized-authoring-compiled-identity.md)).
2. Author translations with Godot’s spreadsheet / CSV workflow (or gettext PO). Example CSV shape:

```csv
keys,en,ja
res://game/dialogue/intro.dlg::12,Hello traveler.,こんにちは旅人。
```

3. Import the CSV so Godot generates `.translation` resources ([CSV translation importer](https://docs.godotengine.org/en/4.7/classes/class_resourceimportercsvtranslation.html); tutorial: [Localization using spreadsheets](https://docs.godotengine.org/en/4.7/tutorials/i18n/localization_using_spreadsheets.html)).
4. Ensure locales are available in **Project Settings → Localization** (and Internationalization docs: [Internationalizing games](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html)).
5. Set the active locale at runtime, e.g. `TranslationServer.set_locale("ja")` (or from player settings / `OS.get_locale_language()`).

Speaker display names remain Presentation-owned via `tr(speaker_id, "speakers")` — keep a separate speakers domain/catalog as needed.

### Optional thin registration

If you author `Translation` resources outside Project Settings auto-load, the **game** may call `TranslationServer.add_translation(translation)` during boot. That stays game-owned — the Integration kit does **not** ship catalog content or a Runtime catalog service.

### Not the primary product story

Showcase demo JSON translation catalogs under `game/dialogue_demo/` are a **demo-local** convenience. Prefer Godot CSV / `.translation` + Project Settings for shipping games.

---

## Related guides

| Doc | Topic |
|-----|--------|
| [integration/README.md](../integration/README.md) | Surface inventory and testing layout |
| [game_command_integration.md](game_command_integration.md) | Manifests + `CommandRegistry` patterns |
| [game_presenter.md](game_presenter.md) | Presenter contract / Presentation |
| [04-runtime-and-integration.md](../../../docs/architecture/dialogue/04-runtime-and-integration.md) | Runtime execution & integration overview |
