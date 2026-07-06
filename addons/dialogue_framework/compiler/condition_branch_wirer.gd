class_name ConditionBranchWirer
extends RefCounted


static func apply(
	built_lines: Array[Dictionary],
	condition_true_branch_ids: Dictionary
) -> void:
	for entry: Dictionary in built_lines:
		var line: Dictionary = entry["line"]
		if CompiledLine.get_kind(line) != LineKind.Kind.CONDITION:
			continue
		var header_id: String = String(entry["id"])
		if not condition_true_branch_ids.has(header_id):
			continue
		line[CompiledLine.KEY_NEXT_ID] = String(condition_true_branch_ids[header_id])
