extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func test_compile_string_produces_compiled_dialogue_resource() -> void:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var compiled: CompiledDialogue = result["compiled"]
	assert_not_null(compiled)
	assert_eq(compiled.source_path, FIXTURE_PATH)
	assert_false(compiled.lines.is_empty())
	assert_eq(compiled.first_title, "start")


func test_dlg_import_plugin_exposes_required_import_methods() -> void:
	var script: Script = load("res://addons/dialogue_framework/compiler/dlg_import_plugin.gd")
	assert_not_null(script)
	assert_true(script.is_tool())
	var method_names: PackedStringArray = PackedStringArray()
	for method: Dictionary in script.get_script_method_list():
		method_names.append(String(method.get("name")))
	assert_true(method_names.has("_get_recognized_extensions"))
	assert_true(method_names.has("_import"))


func test_compile_errors_block_compiled_resource_output() -> void:
	var result: Dictionary = DialogueCompiler.compile_string(
		"not valid dialogue syntax",
		"res://test/invalid.dlg"
	)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])


func test_compile_unknown_game_command_fails_without_manifest() -> void:
	var result: Dictionary = DialogueCompiler.compile_string(
		"@open_shop",
		"res://test/unknown_command.dlg"
	)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])


func test_compile_string_matches_compile_result() -> void:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var compile_result: Dictionary = DialogueCompiler.compile(source_text, FIXTURE_PATH, false)
	var compile_string_result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH, false)
	assert_eq(compile_result["errors"], compile_string_result["errors"])
	assert_eq(compile_result["warnings"], compile_string_result["warnings"])
	assert_not_null(compile_string_result["compiled"])
	assert_eq(
		compile_string_result["compiled"].first_title,
		compile_result["compiled"].first_title
	)


func test_compile_string_strict_errors_without_flag_manifest() -> void:
	var result: Dictionary = DialogueCompiler.compile_string("~ start\nRoll: Hi.", "", true)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])


func test_dlg_import_plugin_uses_compile_entry_point() -> void:
	var source_text: String = FileAccess.get_file_as_string(
		"res://addons/dialogue_framework/compiler/dlg_import_plugin.gd"
	)
	assert_true(source_text.contains("DialogueCompiler.compile("))
	assert_false(source_text.contains("compile_string("))
