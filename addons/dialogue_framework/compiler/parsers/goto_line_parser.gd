class_name GotoLineParser
extends RefCounted


const GOTO_PREFIX := "=>"
const END_TARGET := "END"


static func matches(text: String) -> bool:
	var content: String = text.strip_edges()
	if not content.begins_with(GOTO_PREFIX):
		return false
	return not ChoiceLineParser.matches(text)


static func parse(text: String, source_line_number: int) -> Dictionary:
	if not matches(text):
		return {}
	var target: String = text.strip_edges().substr(GOTO_PREFIX.length()).strip_edges()
	if target.is_empty():
		return {}
	var is_end_target: bool = target.to_upper() == END_TARGET
	return {
		"target_title": target,
		"is_end_target": is_end_target,
		"source_line_number": source_line_number,
	}


static func build_compiled_node(
	line_id: String,
	next_id: String,
	parsed: Dictionary,
	resolved_target_line_id: String = ""
) -> Dictionary:
	if bool(parsed.get("is_end_target", false)):
		return CompiledLine.create_end(line_id, int(parsed["source_line_number"]), next_id)
	var target_line_id: String = resolved_target_line_id
	if target_line_id.is_empty():
		target_line_id = String(parsed.get("target_title", ""))
	return CompiledLine.create_goto(
		line_id,
		int(parsed["source_line_number"]),
		next_id,
		target_line_id
	)
