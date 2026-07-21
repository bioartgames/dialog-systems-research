extends GutTest


func _mock_context() -> GameContext:
	return load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()


func _line_dict(
	p_text: String,
	p_translation_key: String = "",
	p_speaker_id: String = "player"
) -> Dictionary:
	return {
		CompiledLine.KEY_SPEAKER_ID: p_speaker_id,
		CompiledLine.KEY_TEXT: p_text,
		CompiledLine.KEY_TAGS: PackedStringArray(),
		CompiledLine.KEY_TRANSLATION_KEY: (
			p_translation_key if p_translation_key != "" else p_text
		),
		CompiledLine.KEY_NEXT_ID: "next_line",
	}


func test_build_populates_line_step_fields() -> void:
	var line: Dictionary = _line_dict("Hello there.", "hello_key", "roll")
	var step: ConversationStep = LineStepBuilder.build(line, "line_1", _mock_context())
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.line_id, "line_1")
	assert_eq(step.speaker_id, "roll")
	assert_eq(step.text, "Hello there.")
	assert_eq(step.next_line_id, "next_line")


func test_resolve_braces_uses_game_context_display_values() -> void:
	var context: GameContext = _mock_context()
	context.display_values["player_name"] = "Alice"
	var line: Dictionary = _line_dict("Hello {player_name}.")
	var step: ConversationStep = LineStepBuilder.build(line, "line_1", context)
	assert_eq(step.text, "Hello Alice.")


func test_build_uses_translation_server_for_translation_key() -> void:
	var translation := Translation.new()
	translation.add_message("greet_key", "Bonjour.")
	TranslationServer.add_translation(translation)
	var line: Dictionary = _line_dict("Hello there.", "greet_key")
	var step: ConversationStep = LineStepBuilder.build(line, "line_1", _mock_context())
	assert_eq(step.text, "Bonjour.")


func test_build_falls_back_to_source_text_when_translation_missing() -> void:
	var line: Dictionary = _line_dict("Hello there.", "missing_greet_key")
	var step: ConversationStep = LineStepBuilder.build(line, "line_1", _mock_context())
	assert_eq(step.text, "Hello there.")
