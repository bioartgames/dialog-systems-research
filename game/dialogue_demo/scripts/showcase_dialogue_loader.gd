class_name ShowcaseDialogueLoader
extends RefCounted

const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/scenarios/showcase.dlg"


static func dlg_import_is_valid(dlg_path: String) -> bool:
	var import_path: String = "%s.import" % dlg_path
	if not FileAccess.file_exists(import_path):
		return false
	var text: String = FileAccess.get_file_as_string(import_path)
	if text.contains("valid=false"):
		return false
	return text.contains("dest_files=")


static func load_imported(dlg_path: String) -> Dictionary:
	if not dlg_import_is_valid(dlg_path):
		return {
			"compiled": null,
			"source": "import_invalid",
			"errors": PackedStringArray(
				[".dlg import is invalid or missing dest_files for %s" % dlg_path]
			),
		}
	if not ResourceLoader.exists(dlg_path):
		return {
			"compiled": null,
			"source": "missing",
			"errors": PackedStringArray(["Dialogue file not found: %s" % dlg_path]),
		}
	var resource: Resource = ResourceLoader.load(dlg_path)
	if resource is CompiledDialogue:
		return {"compiled": resource as CompiledDialogue, "source": "imported", "errors": PackedStringArray()}
	return {
		"compiled": null,
		"source": "import_load_failed",
		"errors": PackedStringArray(
			["load(%s) did not return CompiledDialogue after valid import." % dlg_path]
		),
	}
