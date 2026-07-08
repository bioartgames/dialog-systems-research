extends SceneTree

const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/scenarios/showcase.dlg"


func _init() -> void:
	var is_valid: bool = ShowcaseDialogueLoader.dlg_import_is_valid(SHOWCASE_DLG_PATH)
	var loaded: bool = ResourceLoader.load(SHOWCASE_DLG_PATH) is CompiledDialogue
	if is_valid and loaded:
		print("IMPORT_AUDIT 1/1")
		quit(0)
		return
	print("FAIL %s valid=%s loaded=%s" % [SHOWCASE_DLG_PATH, is_valid, loaded])
	print("IMPORT_AUDIT 0/1")
	quit(1)
