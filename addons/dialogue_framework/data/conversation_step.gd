class_name ConversationStep
extends RefCounted


var kind: ConversationStepKind.Kind = ConversationStepKind.Kind.LINE
var line_id: String = ""

var speaker_id: String = ""
var text: String = ""
var tags: PackedStringArray = PackedStringArray()
var next_line_id: String = ""

var options: Array[Dictionary] = []
var next_line_id_after: String = ""

var command_name: String = ""
var args_tokens: Array = []

var duration_seconds: float = 0.0


static func create_line(
	p_line_id: String,
	p_speaker_id: String,
	p_text: String,
	p_tags: PackedStringArray = PackedStringArray(),
	p_next_line_id: String = ""
) -> ConversationStep:
	var step := ConversationStep.new()
	step.kind = ConversationStepKind.Kind.LINE
	step.line_id = p_line_id
	step.speaker_id = p_speaker_id
	step.text = p_text
	step.tags = p_tags
	step.next_line_id = p_next_line_id
	return step


static func create_choices(
	p_line_id: String,
	p_options: Array[Dictionary],
	p_next_line_id_after: String = ""
) -> ConversationStep:
	var step := ConversationStep.new()
	step.kind = ConversationStepKind.Kind.CHOICES
	step.line_id = p_line_id
	step.options = p_options
	step.next_line_id_after = p_next_line_id_after
	return step


static func create_command(
	p_line_id: String,
	p_command_name: String,
	p_args_tokens: Array
) -> ConversationStep:
	var step := ConversationStep.new()
	step.kind = ConversationStepKind.Kind.COMMAND
	step.line_id = p_line_id
	step.command_name = p_command_name
	step.args_tokens = p_args_tokens
	return step


static func create_wait(p_line_id: String, p_duration_seconds: float) -> ConversationStep:
	var step := ConversationStep.new()
	step.kind = ConversationStepKind.Kind.WAIT
	step.line_id = p_line_id
	step.duration_seconds = p_duration_seconds
	return step


static func create_end(p_line_id: String) -> ConversationStep:
	var step := ConversationStep.new()
	step.kind = ConversationStepKind.Kind.END
	step.line_id = p_line_id
	return step


static func create_choice_option(
	option_text: String,
	target_line_id: String,
	index: int
) -> Dictionary:
	return {
		"text": option_text,
		"target_line_id": target_line_id,
		"index": index,
	}
