class_name GotoTargetValidator
extends RefCounted


const END_TARGET := "END"


static func apply(
	built_lines: Array[Dictionary],
	titles: Dictionary,
	errors: PackedStringArray
) -> void:
	for entry: Dictionary in built_lines:
		var line: Dictionary = entry["line"]
		match CompiledLine.get_kind(line):
			LineKind.Kind.GOTO:
				_resolve_goto_line(line, titles, errors)
			LineKind.Kind.CHOICE:
				_resolve_choice_line(line, titles, errors)


static func _resolve_goto_line(
	line: Dictionary,
	titles: Dictionary,
	errors: PackedStringArray
) -> void:
	var target_title: String = String(line.get(CompiledLine.KEY_RESOLVED_TARGET_LINE_ID, ""))
	if target_title.is_empty():
		errors.append(
			"Missing goto target at line %d." % int(line[CompiledLine.KEY_SOURCE_LINE_NUMBER])
		)
		return
	if not titles.has(target_title):
		errors.append(
			"Unknown goto target '%s' at line %d."
			% [target_title, int(line[CompiledLine.KEY_SOURCE_LINE_NUMBER])]
		)
		return
	line[CompiledLine.KEY_RESOLVED_TARGET_LINE_ID] = String(titles[target_title])


static func _resolve_choice_line(
	line: Dictionary,
	titles: Dictionary,
	errors: PackedStringArray
) -> void:
	var target_title: String = String(line.get(CompiledLine.KEY_TARGET_LINE_ID, ""))
	if target_title.to_upper() == END_TARGET:
		return
	if not titles.has(target_title):
		errors.append(
			"Unknown choice target '%s' at line %d."
			% [target_title, int(line[CompiledLine.KEY_SOURCE_LINE_NUMBER])]
		)
		return
	line[CompiledLine.KEY_TARGET_LINE_ID] = String(titles[target_title])
