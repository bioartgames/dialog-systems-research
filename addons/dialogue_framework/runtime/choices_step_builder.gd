class_name ChoicesStepBuilder
extends RefCounted


static func build(
	first_choice_line_id: String,
	choice_lines: Array[Dictionary],
	game_context: GameContext,
	format_version: int = DialogueFrameworkVersions.FORMAT_VERSION
) -> ConversationStep:
	var options: Array[Dictionary] = []
	var visible_index: int = 0
	var choice_translation_available: bool = (
		format_version >= DialogueFrameworkVersions.FORMAT_VERSION_CHOICE_TRANSLATION_IDENTITY
	)
	for choice_line: Dictionary in choice_lines:
		if not _choice_passes_condition(choice_line, game_context):
			continue
		var raw_text: String = String(choice_line.get(CompiledLine.KEY_TEXT, ""))
		var display_text: String = raw_text
		if choice_translation_available:
			var translation_key: String = String(choice_line.get(CompiledLine.KEY_TRANSLATION_KEY, ""))
			display_text = LineStepBuilder.resolve_localized_text(raw_text, translation_key, null)
		options.append(
			ConversationStep.create_choice_option(
				display_text,
				String(choice_line.get(CompiledLine.KEY_TARGET_LINE_ID, "")),
				visible_index
			)
		)
		visible_index += 1
	var next_line_id_after: String = ""
	if not choice_lines.is_empty():
		next_line_id_after = String(choice_lines[0].get(CompiledLine.KEY_NEXT_ID, ""))
	return ConversationStep.create_choices(first_choice_line_id, options, next_line_id_after)


static func _choice_passes_condition(choice_line: Dictionary, game_context: GameContext) -> bool:
	var tokens: Array = choice_line.get(CompiledLine.KEY_CONDITION_TOKENS, [])
	if tokens.is_empty():
		return true
	return ConditionEvaluator.evaluate(tokens, game_context)
