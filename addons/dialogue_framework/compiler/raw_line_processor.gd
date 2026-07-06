class_name RawLineProcessor
extends RefCounted


const KEY_RAW_LINE := DlgLexer.KEY_RAW_LINE
const KEY_TEXT := DlgLexer.KEY_TEXT
const KEY_SOURCE_LINE_NUMBER := DlgLexer.KEY_SOURCE_LINE_NUMBER
const KEY_INDENT_LEVEL := DlgLexer.KEY_INDENT_LEVEL
const KEY_IS_EMPTY := DlgLexer.KEY_IS_EMPTY
const KEY_CONTENT := &"content"
const KEY_LINE_ID := &"line_id"


static func process(source_text: String, source_path: String) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	if not DlgLexer.validate_single_file_scope(source_text, source_path):
		errors.append_array(DlgSingleFileScopeEnforcer.get_violations(source_text, source_path))
		return {
			"normalized_lines": [],
			"errors": errors,
			"source_text": source_text,
			"source_path": source_path,
		}

	var normalized_lines: Array[Dictionary] = []
	for token: Dictionary in DlgLexer.tokenize(source_text):
		if bool(token.get(KEY_IS_EMPTY, false)):
			continue
		var raw_line: String = String(token.get(KEY_RAW_LINE, ""))
		var source_line_number: int = int(token.get(KEY_SOURCE_LINE_NUMBER, 0))
		normalized_lines.append({
			KEY_RAW_LINE: raw_line,
			KEY_TEXT: token.get(KEY_TEXT, ""),
			KEY_SOURCE_LINE_NUMBER: source_line_number,
			KEY_INDENT_LEVEL: int(token.get(KEY_INDENT_LEVEL, 0)),
			KEY_IS_EMPTY: false,
			KEY_CONTENT: LineIdOverrideParser.strip_override_prefix(raw_line),
			KEY_LINE_ID: LineIdGenerator.resolve_line_id(raw_line, source_path, source_line_number),
		})

	return {
		"normalized_lines": normalized_lines,
		"errors": errors,
		"source_text": source_text,
		"source_path": source_path,
	}
