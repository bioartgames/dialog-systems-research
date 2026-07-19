@abstract
class_name IDialoguePresenter
extends Node


@abstract func present(step: ConversationStep) -> void


@abstract func dismiss() -> void


## Refresh speaker and line text in-place without interrupting or rebuilding active presentation.
## Called during locale switches while AwaitingChoice so line text updates without touching the
## choices panel. Default no-op preserves backward compatibility with existing custom presenters.
func refresh_line_text(_step: ConversationStep) -> void:
	pass
