class_name LineIdOverrideParser
extends RefCounted


const OVERRIDE_PREFIX := "[id:"


static func matches(raw_line: String) -> bool:
	return not parse_override_id(raw_line).is_empty()


static func parse_override_id(raw_line: String) -> String:
	return LineIdGenerator.parse_author_override(raw_line)


static func strip_override_prefix(raw_line: String) -> String:
	if not matches(raw_line):
		return raw_line.strip_edges()
	var regex: RegEx = RegEx.new()
	regex.compile("^\\s*\\[id:[^\\]]+\\]\\s*")
	return regex.sub(raw_line, "", true).strip_edges()


static func resolve_line_id(
	raw_line: String,
	source_path: String,
	source_line_number: int
) -> String:
	return LineIdGenerator.resolve_line_id(raw_line, source_path, source_line_number)
