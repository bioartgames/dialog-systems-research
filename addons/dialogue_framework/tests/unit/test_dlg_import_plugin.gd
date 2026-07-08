extends GutTest


const SOURCE_PATH := "user://gut_dlg_import_test.dlg"
const SAVE_PATH := "user://gut_dlg_import_test_save.tres"
const FLAG_SETTING := "dialogue_framework/flag_manifest_path"
const DEFAULT_FLAG_PATH := "res://game/dialogue_demo/resources/flag_manifest.tres"


func before_each() -> void:
	DialogueFrameworkProjectSettings.register_settings()
	_cleanup_paths()


func after_each() -> void:
	ProjectSettings.set_setting(FLAG_SETTING, DEFAULT_FLAG_PATH)
	_cleanup_paths()


func _cleanup_paths() -> void:
	if FileAccess.file_exists(SOURCE_PATH):
		DirAccess.remove_absolute(SOURCE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func _write_source(text: String) -> void:
	var file: FileAccess = FileAccess.open(SOURCE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_import_returns_error_on_compile_failure() -> void:
	_write_source("not valid dialogue syntax")
	var result: Error = DlgImportPlugin.import_source(SOURCE_PATH, SAVE_PATH)
	assert_push_error("Unrecognized line at 1.")
	assert_ne(result, OK)
	assert_false(FileAccess.file_exists(SAVE_PATH))


func test_import_saves_tres_on_valid_source() -> void:
	_write_source("~ start\nRoll: Hi.\n=> END\n")
	var result: Error = DlgImportPlugin.import_source(SOURCE_PATH, SAVE_PATH)
	assert_eq(result, OK)
	assert_true(FileAccess.file_exists(SAVE_PATH))


func test_import_warns_when_flag_manifest_path_missing() -> void:
	ProjectSettings.set_setting(FLAG_SETTING, "")
	_write_source("~ start\nRoll: Hi.\n=> END\n")
	var result: Error = DlgImportPlugin.import_source(SOURCE_PATH, SAVE_PATH)
	assert_eq(result, OK)
	assert_push_warning("Dlg import warning")
