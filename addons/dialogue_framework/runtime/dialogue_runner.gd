class_name DialogueRunner
extends RefCounted


const _TRAVERSAL_GUARD_LIMIT: int = 10000


var _compiled: CompiledDialogue = null
var _cursor_line_id: String = ""
var _game_context: GameContext = null


func load(compiled: CompiledDialogue) -> void:
	_compiled = compiled
	_cursor_line_id = ""
	_game_context = null


func set_game_context(context: GameContext) -> void:
	_game_context = context


func init_from_title(title: String) -> void:
	if _compiled == null:
		push_error("DialogueRunner.load() must be called before init_from_title().")
		_cursor_line_id = ""
		return
	_cursor_line_id = _compiled.get_title_line_id(title)
	if _cursor_line_id.is_empty():
		push_error("Unknown title '%s'." % title)


func set_cursor(line_id: String) -> void:
	_cursor_line_id = line_id


func get_cursor_line_id() -> String:
	return _cursor_line_id


func next_step() -> ConversationStep:
	if _compiled == null or _cursor_line_id.is_empty():
		return null
	var yield_line_id: String = _find_yield_line_id(_cursor_line_id)
	if yield_line_id.is_empty():
		_cursor_line_id = ""
		return null
	var line: Dictionary = _compiled.get_line(yield_line_id)
	if line.is_empty():
		_cursor_line_id = ""
		return null
	var step: ConversationStep = _build_step_for_line(line, yield_line_id)
	_cursor_line_id = _cursor_after_yield(line, yield_line_id)
	return step


func peek_step_kind() -> ConversationStepKind.Kind:
	if _compiled == null or _cursor_line_id.is_empty():
		return ConversationStepKind.Kind.END
	var yield_line_id: String = _find_yield_line_id(_cursor_line_id)
	if yield_line_id.is_empty():
		return ConversationStepKind.Kind.END
	var line: Dictionary = _compiled.get_line(yield_line_id)
	if line.is_empty():
		return ConversationStepKind.Kind.END
	return _map_line_kind_to_step_kind(CompiledLine.get_kind(line), line)


func _find_yield_line_id(line_id: String, depth: int = 0) -> String:
	if depth >= _TRAVERSAL_GUARD_LIMIT:
		push_error("DialogueRunner traversal guard tripped.")
		return ""
	if line_id.is_empty() or _compiled == null:
		return ""
	var line: Dictionary = _compiled.get_line(line_id)
	if line.is_empty():
		return ""
	match CompiledLine.get_kind(line):
		LineKind.Kind.TITLE:
			return _find_yield_line_id(String(line.get(CompiledLine.KEY_NEXT_ID, "")), depth + 1)
		LineKind.Kind.GOTO:
			return _find_yield_line_id(
				String(line.get(CompiledLine.KEY_RESOLVED_TARGET_LINE_ID, "")),
				depth + 1
			)
		LineKind.Kind.CONDITION:
			var branch_line_id: String = _resolve_condition_branch(line)
			return _find_yield_line_id(branch_line_id, depth + 1)
		LineKind.Kind.LINE, LineKind.Kind.CHOICE, LineKind.Kind.COMMAND, LineKind.Kind.END:
			return line_id
		_:
			return ""


func _resolve_condition_branch(line: Dictionary) -> String:
	var tokens: Array = line.get(CompiledLine.KEY_CONDITION_TOKENS, [])
	var passes: bool = ConditionEvaluator.evaluate(tokens, _game_context)
	if passes:
		return String(line.get(CompiledLine.KEY_NEXT_ID, ""))
	var sibling_id: String = String(line.get(CompiledLine.KEY_NEXT_SIBLING_ID, ""))
	if not sibling_id.is_empty():
		return sibling_id
	return String(line.get(CompiledLine.KEY_NEXT_ID_AFTER, ""))


func _build_step_for_line(line: Dictionary, line_id: String) -> ConversationStep:
	match CompiledLine.get_kind(line):
		LineKind.Kind.LINE:
			return LineStepBuilder.build(line, line_id, _game_context)
		LineKind.Kind.CHOICE:
			return _build_choices_step(line_id)
		LineKind.Kind.COMMAND:
			return _build_command_or_wait_step(line, line_id)
		LineKind.Kind.END:
			return EndStepBuilder.build(line_id)
		_:
			return ConversationStep.create_end(line_id)


func _build_choices_step(first_choice_line_id: String) -> ConversationStep:
	var choice_lines: Array[Dictionary] = _collect_choice_group(first_choice_line_id)
	var options: Array[Dictionary] = []
	for index: int in choice_lines.size():
		var choice_line: Dictionary = choice_lines[index]
		options.append(
			ConversationStep.create_choice_option(
				String(choice_line.get(CompiledLine.KEY_TEXT, "")),
				String(choice_line.get(CompiledLine.KEY_TARGET_LINE_ID, "")),
				index
			)
		)
	var next_line_id_after: String = String(choice_lines[0].get(CompiledLine.KEY_NEXT_ID, ""))
	return ConversationStep.create_choices(first_choice_line_id, options, next_line_id_after)


func _build_command_or_wait_step(line: Dictionary, line_id: String) -> ConversationStep:
	var command_name: String = String(line.get(CompiledLine.KEY_COMMAND_NAME, ""))
	var args_tokens: Array = line.get(CompiledLine.KEY_ARGS_TOKENS, [])
	if command_name == "wait":
		return ConversationStep.create_wait(line_id, _extract_wait_duration(args_tokens))
	return ConversationStep.create_command(line_id, command_name, args_tokens)


func _collect_choice_group(first_choice_line_id: String) -> Array[Dictionary]:
	var choice_lines: Array[Dictionary] = []
	var sorted_ids: Array[String] = _sorted_line_ids_by_source()
	var start_index: int = sorted_ids.find(first_choice_line_id)
	if start_index < 0:
		return choice_lines
	for index: int in range(start_index, sorted_ids.size()):
		var choice_line: Dictionary = _compiled.get_line(sorted_ids[index])
		if CompiledLine.get_kind(choice_line) != LineKind.Kind.CHOICE:
			break
		choice_lines.append(choice_line)
	return choice_lines


func _sorted_line_ids_by_source() -> Array[String]:
	var line_ids: Array[String] = []
	for line_id: String in _compiled.lines:
		line_ids.append(line_id)
	line_ids.sort_custom(func(left_id: String, right_id: String) -> bool:
		var left_line: Dictionary = _compiled.get_line(left_id)
		var right_line: Dictionary = _compiled.get_line(right_id)
		return int(left_line.get(CompiledLine.KEY_SOURCE_LINE_NUMBER, 0)) < int(
			right_line.get(CompiledLine.KEY_SOURCE_LINE_NUMBER, 0)
		)
	)
	return line_ids


func _cursor_after_yield(line: Dictionary, yield_line_id: String) -> String:
	match CompiledLine.get_kind(line):
		LineKind.Kind.CHOICE:
			return String(_collect_choice_group(yield_line_id)[0].get(CompiledLine.KEY_NEXT_ID, ""))
		LineKind.Kind.END:
			return ""
		_:
			return String(line.get(CompiledLine.KEY_NEXT_ID, ""))


static func _extract_wait_duration(args_tokens: Array) -> float:
	if args_tokens.is_empty():
		return 0.0
	var token: Dictionary = args_tokens[0]
	match String(token.get("type", "")):
		CommandArgumentTokenizer.TYPE_FLOAT:
			return float(token.get("value", 0.0))
		CommandArgumentTokenizer.TYPE_INT:
			return float(token.get("value", 0))
		_:
			return 0.0


static func _map_line_kind_to_step_kind(
	kind: LineKind.Kind,
	line: Dictionary = {}
) -> ConversationStepKind.Kind:
	match kind:
		LineKind.Kind.LINE:
			return ConversationStepKind.Kind.LINE
		LineKind.Kind.CHOICE:
			return ConversationStepKind.Kind.CHOICES
		LineKind.Kind.COMMAND:
			if String(line.get(CompiledLine.KEY_COMMAND_NAME, "")) == "wait":
				return ConversationStepKind.Kind.WAIT
			return ConversationStepKind.Kind.COMMAND
		LineKind.Kind.END:
			return ConversationStepKind.Kind.END
		_:
			return ConversationStepKind.Kind.END
