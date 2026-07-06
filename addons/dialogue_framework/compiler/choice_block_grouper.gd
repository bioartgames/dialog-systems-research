class_name ChoiceBlockGrouper
extends RefCounted


static func apply(built_lines: Array[Dictionary]) -> void:
	var index: int = 0
	while index < built_lines.size():
		if CompiledLine.get_kind(built_lines[index]["line"]) != LineKind.Kind.CHOICE:
			index += 1
			continue
		var group_start: int = index
		while (
			index < built_lines.size()
			and CompiledLine.get_kind(built_lines[index]["line"]) == LineKind.Kind.CHOICE
		):
			index += 1
		var after_group_id: String = ""
		if index < built_lines.size():
			after_group_id = String(built_lines[index]["id"])
		for group_index: int in range(group_start, index):
			built_lines[group_index]["line"][CompiledLine.KEY_NEXT_ID] = after_group_id
