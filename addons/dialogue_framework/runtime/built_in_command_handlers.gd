class_name BuiltInCommandHandlers
extends RefCounted


static func is_non_visual_builtin(command_name: String) -> bool:
	return command_name == "set_flag" or command_name == "emit"


static func handle_set_flag(context: GameContext, args_tokens: Array) -> void:
	if context == null:
		push_error("BuiltInCommandHandlers.set_flag requires GameContext.")
		return
	if args_tokens.size() < 2:
		push_error("BuiltInCommandHandlers.set_flag requires flag name and value.")
		return
	var flag_name: String = String(_token_value(args_tokens[0]))
	if flag_name.is_empty():
		push_error("BuiltInCommandHandlers.set_flag requires a flag name.")
		return
	context.set_flag(flag_name, _token_value(args_tokens[1]))


static func handle_emit(args_tokens: Array, emit_command_executed: Callable) -> void:
	if emit_command_executed == null or not emit_command_executed.is_valid():
		push_error("BuiltInCommandHandlers.emit requires a valid emit callback.")
		return
	var args: Array = []
	for token: Variant in args_tokens:
		if token is Dictionary:
			args.append(_token_value(token))
	emit_command_executed.call("emit", args)


static func register_set_flag_handler(context: GameContext) -> void:
	CommandRegistry.register(
		"set_flag",
		func(packed_args: PackedStringArray) -> void:
			handle_set_flag(context, CommandArgumentTokenizer.tokenize_args(packed_args))
	)


static func register_emit_handler(emit_command_executed: Callable) -> void:
	CommandRegistry.register(
		"emit",
		func(packed_args: PackedStringArray) -> void:
			handle_emit(CommandArgumentTokenizer.tokenize_args(packed_args), emit_command_executed)
	)


static func _token_value(token: Dictionary) -> Variant:
	match String(token.get("type", "")):
		CommandArgumentTokenizer.TYPE_BOOL:
			return bool(token.get("value", false))
		CommandArgumentTokenizer.TYPE_INT:
			return int(token.get("value", 0))
		CommandArgumentTokenizer.TYPE_FLOAT:
			return float(token.get("value", 0.0))
		CommandArgumentTokenizer.TYPE_STRING:
			return String(token.get("value", ""))
		_:
			return token.get("value")
