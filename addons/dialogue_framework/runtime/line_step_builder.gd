class_name LineStepBuilder
extends RefCounted


static var _brace_key_regex: RegEx


static func build(line: Dictionary, line_id: String, context: GameContext) -> ConversationStep:
	var raw_text: String = String(line.get(CompiledLine.KEY_TEXT, ""))
	var translation_key: String = String(line.get(CompiledLine.KEY_TRANSLATION_KEY, ""))
	var display_text: String = _resolve_display_text(raw_text, translation_key, context)
	return ConversationStep.create_line(
		line_id,
		String(line.get(CompiledLine.KEY_SPEAKER_ID, "")),
		display_text,
		line.get(CompiledLine.KEY_TAGS, PackedStringArray()),
		String(line.get(CompiledLine.KEY_NEXT_ID, ""))
	)


static func resolve_braces(text: String, context: GameContext) -> String:
	if text.is_empty() or context == null:
		return text
	var resolved: String = text
	for match: RegExMatch in _get_brace_key_regex().search_all(text):
		var key: String = match.get_string(1)
		var placeholder: String = "{%s}" % key
		resolved = resolved.replace(placeholder, context.get_display_value(key))
	return resolved


static func _resolve_display_text(
	raw_text: String,
	translation_key: String,
	context: GameContext
) -> String:
	var template: String = raw_text
	if not translation_key.is_empty():
		var translated: String = TranslationServer.translate(translation_key)
		if translated != translation_key:
			template = translated
	return resolve_braces(template, context)


static func _get_brace_key_regex() -> RegEx:
	if _brace_key_regex == null:
		_brace_key_regex = RegEx.new()
		_brace_key_regex.compile("\\{([A-Za-z_][A-Za-z0-9_]*)\\}")
	return _brace_key_regex
