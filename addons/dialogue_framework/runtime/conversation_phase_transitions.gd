class_name ConversationPhaseTransitions
extends RefCounted


## Documented ConversationPhase transition events (D2.3).
enum Event {
	START,
	NOTIFY_PRESENTATION_FINISHED,
	ADVANCE_LINE,
	ADVANCE_CHOICES,
	ADVANCE_COMMAND,
	ADVANCE_END,
	CHOOSE,
	CANCEL,
	CONVERSATION_END,
	CLEANUP_TO_IDLE,
}


static func resolve(from_phase: ConversationPhase.Phase, event: Event) -> ConversationPhase.Phase:
	if event == Event.CLEANUP_TO_IDLE:
		if from_phase == ConversationPhase.Phase.Ended:
			return ConversationPhase.Phase.Idle
		return from_phase
	if event == Event.CANCEL or event == Event.CONVERSATION_END:
		if from_phase == ConversationPhase.Phase.Idle:
			return ConversationPhase.Phase.Idle
		if from_phase == ConversationPhase.Phase.Ended:
			return ConversationPhase.Phase.Ended
		return ConversationPhase.Phase.Ended
	match from_phase:
		ConversationPhase.Phase.Idle:
			if event == Event.START:
				return ConversationPhase.Phase.PresentingLine
		ConversationPhase.Phase.PresentingLine:
			if event == Event.NOTIFY_PRESENTATION_FINISHED:
				return ConversationPhase.Phase.AwaitingInput
		ConversationPhase.Phase.AwaitingInput:
			match event:
				Event.ADVANCE_LINE:
					return ConversationPhase.Phase.PresentingLine
				Event.ADVANCE_CHOICES:
					return ConversationPhase.Phase.AwaitingChoice
				Event.ADVANCE_COMMAND:
					return ConversationPhase.Phase.ExecutingCommand
				Event.ADVANCE_END:
					return ConversationPhase.Phase.Ended
		ConversationPhase.Phase.AwaitingChoice:
			if event == Event.CHOOSE:
				return ConversationPhase.Phase.PresentingLine
		ConversationPhase.Phase.ExecutingCommand:
			match event:
				Event.ADVANCE_LINE:
					return ConversationPhase.Phase.PresentingLine
				Event.ADVANCE_CHOICES:
					return ConversationPhase.Phase.AwaitingChoice
				Event.ADVANCE_COMMAND:
					return ConversationPhase.Phase.ExecutingCommand
				Event.ADVANCE_END:
					return ConversationPhase.Phase.Ended
	return from_phase
