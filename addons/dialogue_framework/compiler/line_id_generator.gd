class_name LineIdGenerator


static var _id_override_regex: RegEx


static func _get_override_regex() -> RegEx:
	if _id_override_regex == null:
		_id_override_regex = RegEx.new()
		_id_override_regex.compile("^\\s*\\[id:([^\\]]+)\\]")
	return _id_override_regex


static func parse_author_override(raw_line: String) -> String:
	var match_result: RegExMatch = _get_override_regex().search(raw_line)
	if match_result == null:
		return ""
	return match_result.get_string(1).strip_edges()


static func generate_fallback(source_path: String, source_line_number: int) -> String:
	return "%s::%d" % [source_path, source_line_number]


static func resolve_line_id(
	raw_line: String,
	source_path: String,
	source_line_number: int
) -> String:
	var author_id: String = parse_author_override(raw_line)
	if not author_id.is_empty():
		return author_id
	return generate_fallback(source_path, source_line_number)


static func resolve_translation_key(
	raw_line: String,
	source_path: String,
	source_line_number: int
) -> String:
	return resolve_line_id(raw_line, source_path, source_line_number)
