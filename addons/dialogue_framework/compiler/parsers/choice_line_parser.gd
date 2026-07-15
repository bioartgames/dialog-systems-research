class_name ChoiceLineParser
extends RefCounted


const CHOICE_PREFIX := "-"
const CONDITION_SEPARATOR := " | if "
const END_TARGET := "END"


static func matches(text: String) -> bool:
	return text.strip_edges().begins_with(CHOICE_PREFIX)


static func parse(text: String, source_line_number: int) -> Dictionary:
	if not matches(text):
		return {}
	var content: String = text.strip_edges().substr(CHOICE_PREFIX.length()).strip_edges()
	if content.is_empty() or not content.contains("=>"):
		return {}

	var arrow_index: int = content.find("=>")
	var left: String = content.substr(0, arrow_index).strip_edges()
	var right: String = content.substr(arrow_index + 2).strip_edges()
	if left.is_empty() or right.is_empty():
		return {}

	var choice_text: String = left
	var condition_text: String = ""
	var separator_index: int = left.find(CONDITION_SEPARATOR)
	if separator_index >= 0:
		choice_text = left.substr(0, separator_index).strip_edges()
		condition_text = left.substr(separator_index + CONDITION_SEPARATOR.length()).strip_edges()
	if choice_text.is_empty():
		return {}

	var is_end_target: bool = right.strip_edges().to_upper() == END_TARGET
	return {
		"text": choice_text,
		"condition_text": condition_text,
		"condition_tokens": [],
		"target_title": right.strip_edges(),
		"is_end_target": is_end_target,
		"source_line_number": source_line_number,
	}


static func build_choice_line(
	line_id: String,
	next_id: String,
	parsed: Dictionary,
	target_line_id: String = "",
	translation_key: String = ""
) -> Dictionary:
	var resolved_target: String = target_line_id
	if resolved_target.is_empty():
		resolved_target = String(parsed.get("target_title", ""))
	return CompiledLine.create_choice(
		line_id,
		int(parsed["source_line_number"]),
		next_id,
		String(parsed["text"]),
		parsed.get("condition_tokens", []),
		resolved_target,
		translation_key
	)
