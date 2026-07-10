class_name ConditionBranchExitWirer
extends RefCounted


const KEY_HEADER_IDS := "header_ids"
const KEY_EXIT_LINE_IDS := "exit_line_ids"
const KEY_END_INDEX := "end_index"


static func apply(built_lines: Array[Dictionary], condition_blocks: Array[Dictionary]) -> void:
	if condition_blocks.is_empty():
		return

	var id_to_line: Dictionary = {}
	for entry: Dictionary in built_lines:
		id_to_line[String(entry["id"])] = entry["line"]

	for block: Dictionary in condition_blocks:
		var end_index: int = int(block.get(KEY_END_INDEX, -1))
		if end_index < 0:
			continue

		var continuation_id: String = ""
		if end_index + 1 < built_lines.size():
			continuation_id = String(built_lines[end_index + 1]["id"])

		var header_ids: PackedStringArray = block.get(KEY_HEADER_IDS, PackedStringArray())
		for header_id: String in header_ids:
			if not id_to_line.has(header_id):
				continue
			id_to_line[header_id][CompiledLine.KEY_NEXT_ID_AFTER] = continuation_id

		var exit_line_ids: PackedStringArray = block.get(KEY_EXIT_LINE_IDS, PackedStringArray())
		for exit_id: String in exit_line_ids:
			if exit_id.is_empty() or not id_to_line.has(exit_id):
				continue
			id_to_line[exit_id][CompiledLine.KEY_NEXT_ID] = continuation_id
