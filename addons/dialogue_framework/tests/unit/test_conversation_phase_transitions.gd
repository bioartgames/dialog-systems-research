extends GutTest


func _resolve(from_phase: ConversationPhase.Phase, event: ConversationPhaseTransitions.Event) -> ConversationPhase.Phase:
	return ConversationPhaseTransitions.resolve(from_phase, event)


func test_idle_to_presenting_line_on_start() -> void:
	assert_eq(
		_resolve(ConversationPhase.Phase.Idle, ConversationPhaseTransitions.Event.START),
		ConversationPhase.Phase.PresentingLine
	)


func test_presenting_line_to_awaiting_input_on_notify() -> void:
	assert_eq(
		_resolve(
			ConversationPhase.Phase.PresentingLine,
			ConversationPhaseTransitions.Event.NOTIFY_PRESENTATION_FINISHED
		),
		ConversationPhase.Phase.AwaitingInput
	)


func test_awaiting_input_advance_transitions() -> void:
	assert_eq(
		_resolve(ConversationPhase.Phase.AwaitingInput, ConversationPhaseTransitions.Event.ADVANCE_LINE),
		ConversationPhase.Phase.PresentingLine
	)
	assert_eq(
		_resolve(ConversationPhase.Phase.AwaitingInput, ConversationPhaseTransitions.Event.ADVANCE_CHOICES),
		ConversationPhase.Phase.AwaitingChoice
	)
	assert_eq(
		_resolve(ConversationPhase.Phase.AwaitingInput, ConversationPhaseTransitions.Event.ADVANCE_COMMAND),
		ConversationPhase.Phase.ExecutingCommand
	)
	assert_eq(
		_resolve(ConversationPhase.Phase.AwaitingInput, ConversationPhaseTransitions.Event.ADVANCE_END),
		ConversationPhase.Phase.Ended
	)


func test_awaiting_choice_to_presenting_line_on_choose() -> void:
	assert_eq(
		_resolve(ConversationPhase.Phase.AwaitingChoice, ConversationPhaseTransitions.Event.CHOOSE),
		ConversationPhase.Phase.PresentingLine
	)


func test_executing_command_auto_advance_transitions_match_awaiting_input() -> void:
	assert_eq(
		_resolve(ConversationPhase.Phase.ExecutingCommand, ConversationPhaseTransitions.Event.ADVANCE_LINE),
		ConversationPhase.Phase.PresentingLine
	)
	assert_eq(
		_resolve(ConversationPhase.Phase.ExecutingCommand, ConversationPhaseTransitions.Event.ADVANCE_CHOICES),
		ConversationPhase.Phase.AwaitingChoice
	)
	assert_eq(
		_resolve(ConversationPhase.Phase.ExecutingCommand, ConversationPhaseTransitions.Event.ADVANCE_COMMAND),
		ConversationPhase.Phase.ExecutingCommand
	)
	assert_eq(
		_resolve(ConversationPhase.Phase.ExecutingCommand, ConversationPhaseTransitions.Event.ADVANCE_END),
		ConversationPhase.Phase.Ended
	)


func test_active_phases_transition_to_ended_on_cancel() -> void:
	var active_phases: Array[ConversationPhase.Phase] = [
		ConversationPhase.Phase.PresentingLine,
		ConversationPhase.Phase.AwaitingInput,
		ConversationPhase.Phase.AwaitingChoice,
		ConversationPhase.Phase.ExecutingCommand,
	]
	for phase: ConversationPhase.Phase in active_phases:
		assert_eq(
			_resolve(phase, ConversationPhaseTransitions.Event.CANCEL),
			ConversationPhase.Phase.Ended
		)


func test_ended_to_idle_after_cleanup() -> void:
	assert_eq(
		_resolve(ConversationPhase.Phase.Ended, ConversationPhaseTransitions.Event.CLEANUP_TO_IDLE),
		ConversationPhase.Phase.Idle
	)
