extends GutTest


func test_parses_builtin_and_game_command_syntax() -> void:
	var wait_parsed: Dictionary = CommandLineParser.parse("@wait 1.5", 1)
	assert_eq(wait_parsed["command_name"], "wait")
	assert_eq(wait_parsed["args"], PackedStringArray(["1.5"]))

	var set_flag_parsed: Dictionary = CommandLineParser.parse("@set_flag met_roll true", 2)
	assert_eq(set_flag_parsed["command_name"], "set_flag")
	assert_eq(set_flag_parsed["args"], PackedStringArray(["met_roll", "true"]))

	var game_parsed: Dictionary = CommandLineParser.parse("@open_shop", 3)
	assert_eq(game_parsed["command_name"], "open_shop")
	assert_true(CommandLineParser.supports_command_name("open_shop"))


func test_distinguishes_command_prefix() -> void:
	assert_true(CommandLineParser.matches("@emit door_opened"))
	assert_false(CommandLineParser.matches("Roll: Hello"))


func test_parses_quoted_arguments() -> void:
	var parsed: Dictionary = CommandLineParser.parse("@emit \"door opened\"", 4)
	assert_eq(parsed["command_name"], "emit")
	assert_eq(parsed["args"], PackedStringArray(["door opened"]))


func test_rejects_non_command_lines() -> void:
	assert_true(CommandLineParser.parse("Roll: Hello", 5).is_empty())
