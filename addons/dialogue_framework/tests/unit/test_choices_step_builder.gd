extends GutTest


func _choice_line(
	text: String,
	target: String,
	tokens: Array = [],
	translation_key: String = ""
) -> Dictionary:
	return {
		CompiledLine.KEY_TEXT: text,
		CompiledLine.KEY_TRANSLATION_KEY: translation_key if translation_key != "" else text,
		CompiledLine.KEY_TARGET_LINE_ID: target,
		CompiledLine.KEY_CONDITION_TOKENS: tokens,
		CompiledLine.KEY_NEXT_ID: "after_choices",
	}


func _mock_context() -> GameContext:
	return load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()


func test_build_includes_only_passing_options_with_sequential_index() -> void:
	var context: GameContext = _mock_context()
	context.set_flag("show_secret", true)
	context.set_flag("missing", false)
	var choice_lines: Array[Dictionary] = [
		_choice_line("Always", "target_a"),
		_choice_line(
			"Secret",
			"target_b",
			[{"type": "call", "function": "flag", "arg": "show_secret"}]
		),
		_choice_line(
			"Hidden",
			"target_c",
			[{"type": "call", "function": "flag", "arg": "missing"}]
		),
	]
	var step: ConversationStep = ChoicesStepBuilder.build("choice_1", choice_lines, context)
	assert_eq(step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(step.options.size(), 2)
	assert_eq(step.options[0]["text"], "Always")
	assert_eq(step.options[0]["index"], 0)
	assert_eq(step.options[1]["text"], "Secret")
	assert_eq(step.options[1]["index"], 1)
	assert_eq(step.next_line_id_after, "after_choices")


func test_build_uses_translation_server_for_translation_key() -> void:
	var translation := Translation.new()
	translation.add_message("leave_key", "Partir.")
	TranslationServer.add_translation(translation)
	var choice_lines: Array[Dictionary] = [
		_choice_line("Leave", "target_end", [], "leave_key"),
	]
	var step: ConversationStep = ChoicesStepBuilder.build("choice_1", choice_lines, _mock_context())
	assert_eq(step.options.size(), 1)
	assert_eq(step.options[0]["text"], "Partir.")
	assert_eq(step.options[0]["target_line_id"], "target_end")
	assert_eq(step.options[0]["index"], 0)


func test_build_falls_back_to_source_text_when_translation_missing() -> void:
	var choice_lines: Array[Dictionary] = [
		_choice_line("Leave", "target_end", [], "missing_leave_key"),
	]
	var step: ConversationStep = ChoicesStepBuilder.build("choice_1", choice_lines, _mock_context())
	assert_eq(step.options.size(), 1)
	assert_eq(step.options[0]["text"], "Leave")


func test_build_uses_source_text_for_legacy_format_version_without_translation_lookup() -> void:
	var translation := Translation.new()
	translation.add_message("leave_key", "Partir.")
	TranslationServer.add_translation(translation)
	var choice_lines: Array[Dictionary] = [
		_choice_line("Leave", "target_end", [], "leave_key"),
	]
	var step: ConversationStep = ChoicesStepBuilder.build(
		"choice_1",
		choice_lines,
		_mock_context(),
		1
	)
	assert_eq(step.options.size(), 1)
	assert_eq(step.options[0]["text"], "Leave")
	assert_eq(step.options[0]["target_line_id"], "target_end")
