extends GutTest


func test_loads_manifests_for_editor_import_with_missing_paths() -> void:
	var result: Dictionary = CompileManifestLoader.load_for_compile(
		CompileManifestLoader.ValidationMode.EDITOR_IMPORT
	)
	assert_true(result.has("flag_manifest"))
	assert_true(result.has("command_manifest"))
	assert_true(result["warnings"].size() >= 1 or result["errors"].is_empty())


func test_strict_mode_errors_when_flag_manifest_path_missing() -> void:
	var setting_name: String = DialogueFrameworkProjectSettings.setting_name(
		DialogueFrameworkProjectSettings.FLAG_MANIFEST_PATH
	)
	var previous: Variant = ProjectSettings.get_setting(setting_name)
	ProjectSettings.set_setting(setting_name, "")
	var result: Dictionary = CompileManifestLoader.load_for_compile(
		CompileManifestLoader.ValidationMode.STRICT
	)
	ProjectSettings.set_setting(setting_name, previous)
	assert_false(result["errors"].is_empty())
