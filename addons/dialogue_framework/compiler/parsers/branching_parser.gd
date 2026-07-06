class_name BranchingParser
extends RefCounted

enum BranchKind {
	IF,
	ELIF,
	ELSE,
}


static func matches_header(text: String) -> bool:
	return not parse_header(text, 0).is_empty()


static func parse_header(raw_line: String, source_line_number: int) -> Dictionary:
	var indent_level: int = _count_indent_level(raw_line)
	var content: String = raw_line.strip_edges()
	if content.is_empty():
		return {}

	if content.begins_with("if "):
		return _parse_conditional_header(
			BranchKind.IF,
			content,
			source_line_number,
			indent_level,
			"if "
		)
	if content.begins_with("elif "):
		return _parse_conditional_header(
			BranchKind.ELIF,
			content,
			source_line_number,
			indent_level,
			"elif "
		)
	if content == "else:":
		return {
			"branch_kind": BranchKind.ELSE,
			"condition_text": "",
			"source_line_number": source_line_number,
			"indent_level": indent_level,
		}
	return {}


static func validate_branch_sequence(headers: Array[Dictionary]) -> bool:
	if headers.is_empty():
		return false
	if int(headers[0].get("branch_kind", -1)) != BranchKind.IF:
		return false
	var saw_else: bool = false
	for i: int in range(1, headers.size()):
		var kind: int = int(headers[i].get("branch_kind", -1))
		if saw_else:
			return false
		if kind == BranchKind.ELSE:
			saw_else = true
			if i != headers.size() - 1:
				return false
			continue
		if kind != BranchKind.ELIF:
			return false
	return true


static func build_condition_nodes(
	headers: Array[Dictionary],
	line_ids: PackedStringArray,
	next_id_after: String,
	true_branch_next_ids: PackedStringArray = PackedStringArray()
) -> Array[Dictionary]:
	if not validate_branch_sequence(headers):
		return []
	if line_ids.size() != headers.size():
		return []

	var nodes: Array[Dictionary] = []
	for i: int in headers.size():
		var header: Dictionary = headers[i]
		var next_sibling_id: String = "" if i == headers.size() - 1 else line_ids[i + 1]
		var true_next_id: String = ""
		if i < true_branch_next_ids.size():
			true_next_id = true_branch_next_ids[i]
		var condition_tokens: Array = header.get("condition_tokens", [])
		nodes.append(
			CompiledLine.create_condition(
				line_ids[i],
				int(header["source_line_number"]),
				true_next_id,
				condition_tokens,
				next_sibling_id,
				next_id_after
			)
		)
	return nodes


static func _parse_conditional_header(
	kind: BranchKind,
	content: String,
	source_line_number: int,
	indent_level: int,
	prefix: String
) -> Dictionary:
	if not content.ends_with(":"):
		return {}
	var condition_text: String = content.substr(prefix.length(), content.length() - prefix.length() - 1).strip_edges()
	if condition_text.is_empty():
		return {}
	return {
		"branch_kind": kind,
		"condition_text": condition_text,
		"source_line_number": source_line_number,
		"indent_level": indent_level,
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
