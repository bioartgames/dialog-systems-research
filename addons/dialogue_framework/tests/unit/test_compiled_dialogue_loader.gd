extends GutTest


## IK-3 — CompiledDialogueLoader structured load results.


const LoaderScript := preload(
	"res://addons/dialogue_framework/integration/compiled_dialogue_loader.gd"
)
const FIXTURE_DLG := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"
const TRES_PATH := "user://gut_compiled_dialogue_loader.tres"
const WRONG_TYPE_PATH := "user://gut_compiled_dialogue_loader_wrong.tres"
const TEMP_DLG := "user://gut_compiled_dialogue_loader_temp.dlg"
const TEMP_IMPORT := "user://gut_compiled_dialogue_loader_temp.dlg.import"


func after_each() -> void:
	_remove_if_exists(TRES_PATH)
	_remove_if_exists(WRONG_TYPE_PATH)
	_remove_if_exists(TEMP_DLG)
	_remove_if_exists(TEMP_IMPORT)


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func test_empty_path_returns_actionable_error() -> void:
	var result: Dictionary = LoaderScript.load_compiled("  ")
	assert_null(result["compiled"])
	assert_eq(result["source"], "empty_path")
	assert_gt((result["errors"] as PackedStringArray).size(), 0)


func test_missing_resource_path_returns_missing() -> void:
	var result: Dictionary = LoaderScript.load_compiled(
		"user://gut_compiled_dialogue_loader_does_not_exist.tres"
	)
	assert_null(result["compiled"])
	assert_eq(result["source"], "missing")
	assert_true(String((result["errors"] as PackedStringArray)[0]).contains("not found"))


func test_dlg_without_import_returns_import_invalid() -> void:
	var file: FileAccess = FileAccess.open(TEMP_DLG, FileAccess.WRITE)
	file.store_string("~ start\nRoll: Hi.\n=> END\n")
	file.close()

	var result: Dictionary = LoaderScript.load_compiled(TEMP_DLG)
	assert_null(result["compiled"])
	assert_eq(result["source"], "import_invalid")
	assert_false(LoaderScript.dlg_import_is_valid(TEMP_DLG))


func test_dlg_import_valid_false_is_invalid() -> void:
	var dlg_file: FileAccess = FileAccess.open(TEMP_DLG, FileAccess.WRITE)
	dlg_file.store_string("~ start\nRoll: Hi.\n=> END\n")
	dlg_file.close()
	var import_file: FileAccess = FileAccess.open(TEMP_IMPORT, FileAccess.WRITE)
	import_file.store_string("[remap]\nimporter=\"dialogue_framework.dlg\"\nvalid=false\n")
	import_file.close()

	assert_false(LoaderScript.dlg_import_is_valid(TEMP_DLG))
	var result: Dictionary = LoaderScript.load_compiled(TEMP_DLG)
	assert_eq(result["source"], "import_invalid")


func test_load_compiled_dialogue_tres_succeeds() -> void:
	var dialogue := CompiledDialogue.new()
	dialogue.source_path = "res://tests/loader_fixture.dlg"
	dialogue.first_title = "start"
	dialogue.titles = {"start": "line_start"}
	var err: Error = ResourceSaver.save(dialogue, TRES_PATH)
	assert_eq(err, OK)

	var result: Dictionary = LoaderScript.load_compiled(TRES_PATH)
	assert_eq(result["source"], "resource")
	assert_eq((result["errors"] as PackedStringArray).size(), 0)
	var compiled: CompiledDialogue = result["compiled"] as CompiledDialogue
	assert_not_null(compiled)
	assert_eq(compiled.first_title, "start")
	assert_eq(compiled.get_title_line_id("start"), "line_start")


func test_wrong_resource_type_returns_wrong_type() -> void:
	var plain := Resource.new()
	var err: Error = ResourceSaver.save(plain, WRONG_TYPE_PATH)
	assert_eq(err, OK)

	var result: Dictionary = LoaderScript.load_compiled(WRONG_TYPE_PATH)
	assert_null(result["compiled"])
	assert_eq(result["source"], "wrong_type")
	assert_gt((result["errors"] as PackedStringArray).size(), 0)


func test_load_imported_alias_matches_load_compiled() -> void:
	var a: Dictionary = LoaderScript.load_compiled("")
	var b: Dictionary = LoaderScript.load_imported("")
	assert_eq(a["source"], b["source"])
	assert_eq(a["errors"], b["errors"])


func test_fixture_dlg_loads_when_import_valid() -> void:
	## Skip when the fixture has not been imported in this Godot cache (CI may still
	## exercise the structured-error paths above).
	if not LoaderScript.dlg_import_is_valid(FIXTURE_DLG):
		pending("minimal.dlg import not present in this environment")
		return
	if not ResourceLoader.exists(FIXTURE_DLG):
		pending("minimal.dlg not visible to ResourceLoader")
		return

	var result: Dictionary = LoaderScript.load_compiled(FIXTURE_DLG)
	assert_eq(result["source"], "imported")
	assert_eq((result["errors"] as PackedStringArray).size(), 0)
	assert_true(result["compiled"] is CompiledDialogue)
