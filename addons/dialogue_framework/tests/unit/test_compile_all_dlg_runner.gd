extends GutTest


const CompileAllDlgRunner := preload("res://addons/dialogue_framework/tools/compile_all_dlg_runner.gd")
const FIXTURE_ROOT := "res://addons/dialogue_framework/tests/fixtures/"


func test_collect_dlg_files_finds_fixture_dialogue() -> void:
	var paths: PackedStringArray = CompileAllDlgRunner.collect_dlg_files(FIXTURE_ROOT)
	assert_true(paths.has("res://addons/dialogue_framework/tests/fixtures/minimal.dlg"))
	assert_true(paths.has("res://addons/dialogue_framework/tests/fixtures/branching.dlg"))


func test_run_compiles_fixture_dlg_files_without_strict() -> void:
	var result: Dictionary = CompileAllDlgRunner.run(false, FIXTURE_ROOT)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	assert_eq(int(result["compiled_count"]), int(result["dlg_file_count"]))
	assert_gte(int(result["dlg_file_count"]), 2)


func test_strict_mode_surfaces_manifest_configuration_errors() -> void:
	var flag_setting: String = DialogueFrameworkProjectSettings.setting_name(
		DialogueFrameworkProjectSettings.FLAG_MANIFEST_PATH
	)
	var command_setting: String = DialogueFrameworkProjectSettings.setting_name(
		DialogueFrameworkProjectSettings.COMMAND_MANIFEST_PATH
	)
	var previous_flag: Variant = ProjectSettings.get_setting(flag_setting)
	var previous_command: Variant = ProjectSettings.get_setting(command_setting)
	ProjectSettings.set_setting(flag_setting, "")
	ProjectSettings.set_setting(command_setting, "")
	var result: Dictionary = CompileAllDlgRunner.run(true, FIXTURE_ROOT)
	ProjectSettings.set_setting(flag_setting, previous_flag)
	ProjectSettings.set_setting(command_setting, previous_command)
	assert_false(result["errors"].is_empty())
	assert_true(result["strict"])
	var combined: String = str(result["errors"])
	assert_true(
		combined.contains("FlagManifest") or combined.contains("manifest"),
		"Expected strict manifest validation errors: %s" % combined
	)


func test_compile_all_entry_script_supports_strict_flag() -> void:
	var script_text: String = FileAccess.get_file_as_string(
		"res://addons/dialogue_framework/tools/compile_all_dlg.gd"
	)
	assert_true(script_text.contains("--strict"))
	assert_true(script_text.contains("CompileAllDlgRunner.run"))
	assert_true(script_text.contains("EXIT_COMPILE_FAILURE"))
