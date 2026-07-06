extends GutTest


func before_each() -> void:
	CommandRegistry.clear_for_tests()


func test_set_flag_parses_name_and_bool_value_from_args_tokens() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	var args_tokens: Array = [
		{"type": CommandArgumentTokenizer.TYPE_STRING, "value": "met_roll"},
		{"type": CommandArgumentTokenizer.TYPE_BOOL, "value": true},
	]
	BuiltInCommandHandlers.handle_set_flag(context, args_tokens)
	assert_eq(context.get_flag("met_roll"), true)


func test_set_flag_parses_int_and_string_values() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	BuiltInCommandHandlers.handle_set_flag(
		context,
		[
			{"type": CommandArgumentTokenizer.TYPE_STRING, "value": "scrap_count"},
			{"type": CommandArgumentTokenizer.TYPE_INT, "value": 12},
		]
	)
	assert_eq(context.get_flag("scrap_count"), 12)
	BuiltInCommandHandlers.handle_set_flag(
		context,
		[
			{"type": CommandArgumentTokenizer.TYPE_STRING, "value": "note"},
			{"type": CommandArgumentTokenizer.TYPE_STRING, "value": "hello"},
		]
	)
	assert_eq(context.get_flag("note"), "hello")


func test_set_flag_requires_game_context() -> void:
	BuiltInCommandHandlers.handle_set_flag(null, [])
	assert_push_error("requires GameContext")


func test_set_flag_requires_name_and_value_tokens() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	BuiltInCommandHandlers.handle_set_flag(context, [])
	assert_push_error("requires flag name and value")


func test_set_flag_registry_handler_writes_via_context() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	BuiltInCommandHandlers.register_set_flag_handler(context)
	await CommandRegistry.dispatch("set_flag", PackedStringArray(["met_roll", "true"]))
	assert_eq(context.get_flag("met_roll"), true)


func test_emit_invokes_command_executed_with_emit_payload() -> void:
	var state: Dictionary = {"command_name": "", "args": []}
	var emit_callback: Callable = func(command_name: String, args: Array) -> void:
		state.command_name = command_name
		state.args = args
	var args_tokens: Array = [
		{"type": CommandArgumentTokenizer.TYPE_STRING, "value": "door_opened"},
		{"type": CommandArgumentTokenizer.TYPE_INT, "value": 2},
	]
	BuiltInCommandHandlers.handle_emit(args_tokens, emit_callback)
	assert_eq(state.command_name, "emit")
	assert_eq(state.args, ["door_opened", 2])


func test_emit_registry_handler_emits_command_executed() -> void:
	var state: Dictionary = {"command_name": "", "args": []}
	var emit_callback: Callable = func(command_name: String, args: Array) -> void:
		state.command_name = command_name
		state.args = args
	BuiltInCommandHandlers.register_emit_handler(emit_callback)
	await CommandRegistry.dispatch("emit", PackedStringArray(["wave_started"]))
	assert_eq(state.command_name, "emit")
	assert_eq(state.args, ["wave_started"])
