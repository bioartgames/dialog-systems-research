extends GutTest


func before_each() -> void:
	DialogueFrameworkProjectSettings.register_settings()


func test_manifest_path_settings_registered_with_game_demo_paths() -> void:
	assert_true(ProjectSettings.has_setting("dialogue_framework/flag_manifest_path"))
	assert_true(ProjectSettings.has_setting("dialogue_framework/command_manifest_path"))
	assert_eq(
		DialogueFrameworkProjectSettings.get_flag_manifest_path(),
		"res://game/dialogue_demo/resources/flag_manifest.tres"
	)
	assert_eq(
		DialogueFrameworkProjectSettings.get_command_manifest_path(),
		"res://game/dialogue_demo/resources/command_manifest.tres"
	)


func test_compile_processor_path_registered_with_empty_default() -> void:
	assert_true(ProjectSettings.has_setting("dialogue_framework/compile_processor_path"))
	assert_eq(DialogueFrameworkProjectSettings.get_compile_processor_path(), "")
	assert_null(DialogueFrameworkProjectSettings.resolve_compile_processor_script())


func test_compile_processor_resolves_script_when_path_set() -> void:
	var setting_name: String = DialogueFrameworkProjectSettings.setting_name(
		DialogueFrameworkProjectSettings.COMPILE_PROCESSOR_PATH
	)
	var fixture_path: String = "res://addons/dialogue_framework/tests/fixtures/mock_compile_processor.gd"
	ProjectSettings.set_setting(setting_name, fixture_path)
	assert_eq(
		DialogueFrameworkProjectSettings.resolve_compile_processor_script().resource_path,
		fixture_path
	)
	ProjectSettings.set_setting(setting_name, "")
