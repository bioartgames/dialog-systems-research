class_name CommandStepBuilder
extends RefCounted


static func build(line: Dictionary, line_id: String) -> ConversationStep:
	var command_name: String = String(line.get(CompiledLine.KEY_COMMAND_NAME, ""))
	var args_tokens: Array = line.get(CompiledLine.KEY_ARGS_TOKENS, [])
	if command_name == "wait":
		return WaitStepBuilder.build(line_id, args_tokens)
	return ConversationStep.create_command(line_id, command_name, args_tokens)
