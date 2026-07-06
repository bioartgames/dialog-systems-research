extends GutTest


const COMMAND_MANIFEST_PATH := "res://addons/dialogue_framework/tests/fixtures/test_command_manifest.tres"


func test_allows_built_in_commands_without_manifest_path() -> void:
	var result: Dictionary = CommandManifestValidator.validate_command("wait", null, false, 1)
	assert_true(bool(result["allowed"]))


func test_rejects_unknown_game_command_without_manifest_path() -> void:
	var result: Dictionary = CommandManifestValidator.validate_command("open_shop", null, false, 2)
	assert_false(bool(result["allowed"]))


func test_allows_manifest_declared_game_command() -> void:
	var manifest: CommandManifest = load(COMMAND_MANIFEST_PATH) as CommandManifest
	var result: Dictionary = CommandManifestValidator.validate_command("open_shop", manifest, false, 3)
	assert_true(bool(result["allowed"]))


func test_strict_mode_rejects_unknown_game_command_without_manifest_path() -> void:
	var result: Dictionary = CommandManifestValidator.validate_command("open_shop", null, true, 4)
	assert_false(bool(result["allowed"]))
	assert_true(String(result["error"]).contains("strict"))


func test_builtin_only_compile_without_command_manifest() -> void:
	var source: String = "@wait 1.0"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source,
		"res://test/commands.dlg",
		false
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
