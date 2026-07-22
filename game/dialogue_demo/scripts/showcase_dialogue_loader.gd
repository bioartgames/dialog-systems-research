class_name ShowcaseDialogueLoader
extends RefCounted

## Demo-local thin wrapper over Integration kit CompiledDialogueLoader (ADR-024 IK-7).
## Prefer CompiledDialogueLoader directly in new game code.


const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/scenarios/showcase.dlg"
const _CompiledDialogueLoader := preload(
	"res://addons/dialogue_framework/integration/compiled_dialogue_loader.gd"
)


static func dlg_import_is_valid(dlg_path: String) -> bool:
	return _CompiledDialogueLoader.dlg_import_is_valid(dlg_path)


static func load_imported(dlg_path: String) -> Dictionary:
	return _CompiledDialogueLoader.load_imported(dlg_path)
