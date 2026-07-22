class_name DialoguePresentationInputListener
extends Node


## Default dialogue UX input (ADR-016 D22.1). Consumes DialoguePresentationInput and
## drives ConversationController / presenter skip-navigate APIs.

## Input mapping resource for skip / advance / choice actions.
@export var input: DialoguePresentationInput
## Path to an [IDialoguePresenter] that receives skip / navigate / confirm calls.
@export_node_path("IDialoguePresenter") var presenter_path: NodePath
## When [code]false[/code], this listener ignores all unhandled input.
@export var listening_enabled: bool = true

var _presenter_node: Node


func _ready() -> void:
	if not presenter_path.is_empty():
		_presenter_node = get_node(presenter_path)


func set_listening_enabled(enabled: bool) -> void:
	listening_enabled = enabled


func _unhandled_input(event: InputEvent) -> void:
	if not listening_enabled or input == null or _presenter_node == null:
		return
	if not event.is_pressed() or event.is_echo():
		return
	var phase: ConversationPhase.Phase = ConversationController.get_debug_state()["phase"]
	match phase:
		ConversationPhase.Phase.PresentingLine:
			if _is_action(event, input.skip_typewriter_action):
				_call_presenter(&"request_skip_typewriter")
				get_viewport().set_input_as_handled()
		ConversationPhase.Phase.AwaitingInput:
			if _is_action(event, input.advance_line_action):
				ConversationController.advance()
				get_viewport().set_input_as_handled()
		ConversationPhase.Phase.AwaitingChoice:
			if (
				_is_action(event, input.navigate_choice_up_action)
				or _is_action(event, input.navigate_choice_up_alt_action)
			):
				_call_presenter(&"navigate_choice", -1)
				get_viewport().set_input_as_handled()
			elif (
				_is_action(event, input.navigate_choice_down_action)
				or _is_action(event, input.navigate_choice_down_alt_action)
			):
				_call_presenter(&"navigate_choice", 1)
				get_viewport().set_input_as_handled()
			elif _is_action(event, input.confirm_choice_action):
				_call_presenter(&"confirm_selected_choice")
				get_viewport().set_input_as_handled()


func _is_action(event: InputEvent, action: StringName) -> bool:
	return not action.is_empty() and event.is_action(action)


func _call_presenter(method: StringName, arg: Variant = null) -> void:
	if _presenter_node == null or not _presenter_node.has_method(method):
		return
	if arg == null:
		_presenter_node.call(method)
	else:
		_presenter_node.call(method, arg)
