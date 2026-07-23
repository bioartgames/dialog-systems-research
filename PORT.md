# Porting Dialogue Framework into a game

One-page map: what to copy into a **Godot 4.7** game for Dialogue Framework **v0**.

## Copy into the game (required)

- `addons/dialogue_framework/` — entire addon (Runtime, compiler/import, Presentation, Integration, and `tests/`). Copy the whole folder for the simplest drag-and-drop; no pruning step.

## Copy when using Ui React HUDs

- `addons/ui_react/` — required if the game uses `presentation/ui_react_dialogue_hud.tscn` or other Ui React slots/templates.

Native HUD scenes (`native_dialogue_hud*.tscn`) work **without** `ui_react`.

## Enable after copy

1. **Project → Project Settings → Plugins** — enable **Dialogue Framework** (registers the `ConversationController` autoload).
2. If using Ui React HUDs — enable the **Ui React** editor plugin for that addon’s tooling; the HUD still needs `addons/ui_react/` scripts on disk either way.
3. Set Project Settings under **Dialogue Framework**:
   - `dialogue_framework/flag_manifest_path`
   - `dialogue_framework/command_manifest_path`
4. Author `.dlg` files under the game project; Godot reimports them to `CompiledDialogue`.
5. Wire start/context/commands/presenter per [addons/dialogue_framework/docs/integration_kit_adoption.md](addons/dialogue_framework/docs/integration_kit_adoption.md).

## Do not copy

| Path | Why |
|------|-----|
| `addons/dialogic/` | Removed; was research-only (also listed in `.gitignore`) |
| `addons/gut/` | Test harness for this research project |
| `game/dialogue_demo/` | Demo reference — rebuild game scenes, `.dlg`, and translations |
| `docs/architecture/dialogue/research/` | Historical research notes |
| `docs/architecture/dialogue/planning/` | Planning / outlines |
| `tools/` | Linear/DAG sync helpers |
| `.cursor/` | Agent rules for this repo |

## Optional docs to skim (not required to copy)

- [addons/dialogue_framework/docs/integration_kit_adoption.md](addons/dialogue_framework/docs/integration_kit_adoption.md)
- [addons/dialogue_framework/README.md](addons/dialogue_framework/README.md)
- [docs/developer-guide.md](docs/developer-guide.md)

## Closed experiment

Authoring Tooling v0 (allowlist manifests + Dialogue Navigator dock) was prototyped then **hard-reset** off `main` before this close-out. Ship v0 is **import plugin + Integration kit**; no Navigator; visual editor remains deferred ([ADR-013](docs/architecture/dialogue/decisions/013-future-editor.md)).
