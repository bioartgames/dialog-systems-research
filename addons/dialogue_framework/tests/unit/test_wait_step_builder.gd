extends GutTest


func test_build_wait_step_parses_float_duration() -> void:
	var step: ConversationStep = WaitStepBuilder.build(
		"wait_1",
		[{"type": CommandArgumentTokenizer.TYPE_FLOAT, "value": 2.5}]
	)
	assert_eq(step.kind, ConversationStepKind.Kind.WAIT)
	assert_eq(step.duration_seconds, 2.5)


func test_build_wait_step_parses_int_duration() -> void:
	var step: ConversationStep = WaitStepBuilder.build(
		"wait_2",
		[{"type": CommandArgumentTokenizer.TYPE_INT, "value": 3}]
	)
	assert_eq(step.duration_seconds, 3.0)
