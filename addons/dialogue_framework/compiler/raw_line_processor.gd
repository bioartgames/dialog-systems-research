class_name RawLineProcessor
extends RefCounted

const _COMPILE_PROCESSOR_RUNNER := preload("res://addons/dialogue_framework/compiler/compile_processor_runner.gd")

const KEY_RAW_LINE := DlgLexer.KEY_RAW_LINE
const KEY_TEXT := DlgLexer.KEY_TEXT
const KEY_SOURCE_LINE_NUMBER := DlgLexer.KEY_SOURCE_LINE_NUMBER
const KEY_INDENT_LEVEL := DlgLexer.KEY_INDENT_LEVEL
const KEY_IS_EMPTY := DlgLexer.KEY_IS_EMPTY
const KEY_CONTENT := &"content"
const KEY_LINE_ID := &"line_id"


static func process(
	source_text: String,
	source_path: String,
	processor: RefCounted = null
) -> Dictionary:
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
		var raw_line: String = _COMPILE_PROCESSOR_RUNNER.preprocess_line(
			processor,
			String(token.get(KEY_RAW_LINE, ""))
		)
		var source_line_number: int = int(token.get(KEY_SOURCE_LINE_NUMBER, 0))
		normalized_lines.append({
			KEY_RAW_LINE: raw_line,
			KEY_TEXT: raw_line.strip_edges(),
			KEY_SOURCE_LINE_NUMBER: source_line_number,
			KEY_INDENT_LEVEL: _count_indent_level(raw_line),
			KEY_IS_EMPTY: raw_line.strip_edges().is_empty(),
			KEY_CONTENT: LineIdOverrideParser.strip_override_prefix(raw_line),
			KEY_LINE_ID: LineIdGenerator.resolve_line_id(raw_line, source_path, source_line_number),
		})

	return {
		"normalized_lines": normalized_lines,
		"errors": errors,
		"source_text": source_text,
		"source_path": source_path,
	}


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
