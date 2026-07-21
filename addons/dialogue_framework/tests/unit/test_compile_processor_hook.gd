extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/transforming_compile_processor.gd"
const SETTING_NAME := "dialogue_framework/compile_processor_path"


func before_each() -> void:
	DialogueFrameworkProjectSettings.register_settings()
	ProjectSettings.set_setting(SETTING_NAME, "")


func after_each() -> void:
	ProjectSettings.set_setting(SETTING_NAME, "")


func test_compile_skips_processor_when_path_empty() -> void:
	var source_text: String = "~ start\nHero: Hi."
	var result: Dictionary = DialogueCompiler.compile_string(source_text, "res://test.dlg")
	assert_true(result["errors"].is_empty())
	var line: Dictionary = _find_line_kind(result["compiled"].lines, LineKind.Kind.LINE)
	assert_eq(String(line[CompiledLine.KEY_SPEAKER_ID]), "Hero")
	assert_eq(String(line[CompiledLine.KEY_TEXT]), "Hi.")


func test_compile_invokes_preprocess_and_post_process_when_path_set() -> void:
	ProjectSettings.set_setting(SETTING_NAME, FIXTURE_PATH)
	var source_text: String = "~ start\nHero: Hi."
	var result: Dictionary = DialogueCompiler.compile_string(source_text, "res://test.dlg")
	assert_true(result["errors"].is_empty())
	var line: Dictionary = _find_line_kind(result["compiled"].lines, LineKind.Kind.LINE)
	assert_eq(String(line[CompiledLine.KEY_SPEAKER_ID]), "post_processed")
	assert_eq(String(line[CompiledLine.KEY_TEXT]), "Hello.")


func test_compile_rejects_processor_that_mutates_translation_identity() -> void:
	ProjectSettings.set_setting(
		SETTING_NAME,
		"res://addons/dialogue_framework/tests/fixtures/identity_mutating_compile_processor.gd"
	)
	var source_text: String = "~ start\n[id:stable_key] Roll: Hi.\n"
	var result: Dictionary = DialogueCompiler.compile_string(source_text, "res://test.dlg")
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])
	assert_true(
		String(result["errors"][0]).contains("Compile processor modified translation identity")
	)


func _find_line_kind(lines: Dictionary, kind: LineKind.Kind) -> Dictionary:
	for line: Dictionary in lines.values():
		if CompiledLine.get_kind(line) == kind:
			return line
	assert_true(false, "Missing compiled line kind %s" % kind)
	return {}
