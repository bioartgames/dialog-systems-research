class_name DialogueRunner
extends RefCounted


var _compiled: CompiledDialogue = null
var _cursor_line_id: String = ""


func load(compiled: CompiledDialogue) -> void:
	_compiled = compiled
	_cursor_line_id = ""


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


func next_step() -> ConversationStep:
	return null


func peek_step_kind() -> ConversationStepKind.Kind:
	if _compiled == null or _cursor_line_id.is_empty():
		return ConversationStepKind.Kind.END
	var line: Dictionary = _compiled.get_line(_cursor_line_id)
	if line.is_empty():
		return ConversationStepKind.Kind.END
	return _map_line_kind_to_step_kind(CompiledLine.get_kind(line))


static func _map_line_kind_to_step_kind(kind: LineKind.Kind) -> ConversationStepKind.Kind:
	match kind:
		LineKind.Kind.LINE:
			return ConversationStepKind.Kind.LINE
		LineKind.Kind.CHOICE:
			return ConversationStepKind.Kind.CHOICES
		LineKind.Kind.COMMAND:
			return ConversationStepKind.Kind.COMMAND
		LineKind.Kind.END:
			return ConversationStepKind.Kind.END
		_:
			return ConversationStepKind.Kind.LINE
