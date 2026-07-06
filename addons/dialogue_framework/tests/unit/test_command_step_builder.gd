extends GutTest


func test_build_command_step_passes_args_tokens() -> void:
	var line: Dictionary = {
		CompiledLine.KEY_COMMAND_NAME: "set_flag",
		CompiledLine.KEY_ARGS_TOKENS: [
			{"type": CommandArgumentTokenizer.TYPE_STRING, "value": "met_roll"},
			{"type": CommandArgumentTokenizer.TYPE_BOOL, "value": true},
		],
	}
	var step: ConversationStep = CommandStepBuilder.build(line, "cmd_1")
	assert_eq(step.kind, ConversationStepKind.Kind.COMMAND)
	assert_eq(step.line_id, "cmd_1")
	assert_eq(step.command_name, "set_flag")
	assert_eq(step.args_tokens.size(), 2)


func test_build_wait_command_yields_wait_step() -> void:
	var line: Dictionary = {
		CompiledLine.KEY_COMMAND_NAME: "wait",
		CompiledLine.KEY_ARGS_TOKENS: [
			{"type": CommandArgumentTokenizer.TYPE_FLOAT, "value": 1.5},
		],
	}
	var step: ConversationStep = CommandStepBuilder.build(line, "wait_1")
	assert_eq(step.kind, ConversationStepKind.Kind.WAIT)
	assert_eq(step.duration_seconds, 1.5)
