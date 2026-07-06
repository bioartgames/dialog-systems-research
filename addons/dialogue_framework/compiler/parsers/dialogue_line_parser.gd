class_name DialogueLineParser
extends RefCounted

static func matches(text: String) -> bool:
	var content: String = _content_without_id_override(text)
	if content.is_empty():
		return false
	if TitleEntryParser.matches(content):
		return false
	if content.begins_with("-"):
		return false
	if content.begins_with("@"):
		return false
	if BranchingParser.matches_header(content):
		return false
	var colon_index: int = content.find(":")
	return colon_index > 0


static func parse(text: String, source_line_number: int) -> Dictionary:
	if not matches(text):
		return {}
	var content: String = _content_without_id_override(text)
	var colon_index: int = content.find(":")
	var speaker_id: String = content.substr(0, colon_index).strip_edges()
	var dialogue_text: String = content.substr(colon_index + 1).strip_edges()
	if speaker_id.is_empty():
		return {}
	return {
		"speaker_id": speaker_id,
		"text": dialogue_text,
		"source_line_number": source_line_number,
	}


static func _content_without_id_override(text: String) -> String:
	var override_id: String = LineIdGenerator.parse_author_override(text)
	if override_id.is_empty():
		return text.strip_edges()
	var regex: RegEx = RegEx.new()
	regex.compile("^\\s*\\[id:[^\\]]+\\]\\s*")
	var stripped: String = regex.sub(text, "", true)
	return stripped.strip_edges()
