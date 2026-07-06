extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/test_command_manifest.tres"


func test_built_in_commands_are_valid() -> void:
	for command_name: String in CommandManifest.BUILT_IN_COMMANDS:
		assert_true(CommandManifest.is_built_in_command(command_name))


func test_loads_from_path_and_validates_game_commands() -> void:
	var manifest: CommandManifest = CommandManifest.load_from_path(FIXTURE_PATH)
	assert_not_null(manifest)
	assert_true(manifest.is_valid_command("open_shop"))
	assert_false(manifest.is_valid_command("unknown_command"))


func test_built_in_commands_valid_without_manifest_entries() -> void:
	var manifest := CommandManifest.new()
	assert_true(manifest.is_valid_command("wait"))
	assert_true(manifest.is_valid_command("set_flag"))
	assert_true(manifest.is_valid_command("emit"))
