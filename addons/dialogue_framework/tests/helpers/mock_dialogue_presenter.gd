extends IDialoguePresenter


var last_step: ConversationStep = null
var present_call_count: int = 0
var dismiss_call_count: int = 0


func present(step: ConversationStep) -> void:
	last_step = step
	present_call_count += 1


func dismiss() -> void:
	dismiss_call_count += 1
