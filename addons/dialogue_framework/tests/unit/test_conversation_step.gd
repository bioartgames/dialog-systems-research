extends GutTest


func test_line_step_fields() -> void:
	var step := ConversationStep.create_line(
		"line_1",
		"Roll",
		"Welcome.",
		PackedStringArray(["voice=path"]),
		"line_2"
	)
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.line_id, "line_1")
	assert_eq(step.speaker_id, "Roll")
	assert_eq(step.text, "Welcome.")
	assert_eq(step.tags, PackedStringArray(["voice=path"]))
	assert_eq(step.next_line_id, "line_2")


func test_choices_step_fields() -> void:
	var options: Array[Dictionary] = [
		ConversationStep.create_choice_option("Buy", "shop", 0),
		ConversationStep.create_choice_option("Leave", "end", 1),
	]
	var step := ConversationStep.create_choices("choice_group", options, "after")
	assert_eq(step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(step.options.size(), 2)
	assert_eq(step.next_line_id_after, "after")


func test_command_wait_and_end_steps() -> void:
	var command := ConversationStep.create_command("c1", "wait", ["1.5"])
	assert_eq(command.kind, ConversationStepKind.Kind.COMMAND)
	assert_eq(command.command_name, "wait")
	assert_eq(command.args_tokens, ["1.5"])

	var wait_step := ConversationStep.create_wait("w1", 2.5)
	assert_eq(wait_step.kind, ConversationStepKind.Kind.WAIT)
	assert_almost_eq(wait_step.duration_seconds, 2.5, 0.001)

	var end_step := ConversationStep.create_end("e1")
	assert_eq(end_step.kind, ConversationStepKind.Kind.END)
	assert_eq(end_step.line_id, "e1")


func test_conversation_step_has_no_portrait_field() -> void:
	var script: Script = ConversationStep
	for property: Dictionary in script.get_script_property_list():
		assert_ne(
			String(property.get("name")),
			"portrait",
			"ConversationStep must not define a portrait field (D11.4)"
		)
