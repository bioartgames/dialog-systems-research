class_name DlgLexer
extends RefCounted


const DLG_EXTENSION := ".dlg"

const KEY_RAW_LINE := &"raw_line"
const KEY_TEXT := &"text"
const KEY_SOURCE_LINE_NUMBER := &"source_line_number"
const KEY_INDENT_LEVEL := &"indent_level"
const KEY_IS_EMPTY := &"is_empty"


static func is_dlg_path(path: String) -> bool:
	return path.get_extension() == DLG_EXTENSION.trim_prefix(".")


static func tokenize(source_text: String) -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	var raw_lines: PackedStringArray = source_text.split("\n", true)
	for index: int in raw_lines.size():
		var raw_line: String = raw_lines[index]
		tokens.append({
			KEY_RAW_LINE: raw_line,
			KEY_TEXT: raw_line.strip_edges(),
			KEY_SOURCE_LINE_NUMBER: index + 1,
			KEY_INDENT_LEVEL: _count_indent_level(raw_line),
			KEY_IS_EMPTY: raw_line.strip_edges().is_empty(),
		})
	return tokens


static func validate_single_file_scope(source_text: String, source_path: String = "") -> bool:
	return find_scope_violations(source_text, source_path).is_empty()


static func find_scope_violations(source_text: String, source_path: String = "") -> PackedStringArray:
	var violations: PackedStringArray = PackedStringArray()
	var import_regex: RegEx = RegEx.new()
	import_regex.compile("^\\s*import\\s+")
	var using_regex: RegEx = RegEx.new()
	using_regex.compile("^\\s*using\\s+")
	var external_dlg_regex: RegEx = RegEx.new()
	external_dlg_regex.compile("res://[^\\s\"']+\\.dlg")

	for token: Dictionary in tokenize(source_text):
		if bool(token.get(KEY_IS_EMPTY, false)):
			continue
		var raw_line: String = String(token.get(KEY_RAW_LINE, ""))
		if import_regex.search(raw_line) != null:
			violations.append(
				"Cross-file import is not supported in v1 (line %d)." % int(token[KEY_SOURCE_LINE_NUMBER])
			)
			continue
		if using_regex.search(raw_line) != null:
			violations.append(
				"Cross-file using directive is not supported in v1 (line %d)." % int(token[KEY_SOURCE_LINE_NUMBER])
			)
			continue
		for match: RegExMatch in external_dlg_regex.search_all(raw_line):
			var referenced_path: String = match.get_string()
			if source_path.is_empty() or referenced_path != source_path:
				violations.append(
					"Cross-file .dlg reference is not supported in v1 (line %d): %s"
					% [int(token[KEY_SOURCE_LINE_NUMBER]), referenced_path]
				)
	return violations


static func _count_indent_level(raw_line: String) -> int:
	var spaces: int = 0
	for i: int in raw_line.length():
		var character: String = raw_line[i]
		if character == " ":
			spaces += 1
		elif character == "\t":
			spaces += 4
		else:
			break
	return int(spaces / 4)
