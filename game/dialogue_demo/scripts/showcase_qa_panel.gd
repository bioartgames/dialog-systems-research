extends Control


signal log_cleared


@onready var _log: RichTextLabel = $Margin/VBox/Log


func _ready() -> void:
	_log.scroll_following = true
	clear_log()


func clear_log() -> void:
	_log.clear()
	_log.append_text("[b]Dialogue Framework QA Log[/b]\n")
	log_cleared.emit()


func log_event(category: String, message: String) -> void:
	var stamp: String = Time.get_time_string_from_system()
	_log.append_text("[%s] [color=cyan]%s[/color] %s\n" % [stamp, category, message])


func log_phase(phase: ConversationPhase.Phase, line_id: String, step_kind: ConversationStepKind.Kind) -> void:
	log_event(
		"phase",
		"%s | line=%s | step=%s"
		% [_phase_label(phase), line_id, step_kind]
	)


func _phase_label(phase: ConversationPhase.Phase) -> String:
	match phase:
		ConversationPhase.Phase.Idle:
			return "Idle"
		ConversationPhase.Phase.PresentingLine:
			return "PresentingLine"
		ConversationPhase.Phase.AwaitingInput:
			return "AwaitingInput"
		ConversationPhase.Phase.AwaitingChoice:
			return "AwaitingChoice"
		ConversationPhase.Phase.ExecutingCommand:
			return "ExecutingCommand"
		ConversationPhase.Phase.Ended:
			return "Ended"
		_:
			return str(phase)
