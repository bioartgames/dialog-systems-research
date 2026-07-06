extends Node


## Public autoload facade for dialogue conversations (D1.5, D2.1).
## Autoload singleton name: ConversationController (no class_name — avoids global name collision).

signal step_ready(step: ConversationStep)
signal conversation_ended(compiled: CompiledDialogue)
signal conversation_cancelled
signal command_executed(command_name: String, args: Array)


var _phase: ConversationPhase.Phase = ConversationPhase.Phase.Idle
var _runner: DialogueRunner = null
var _compiled: CompiledDialogue = null
var _game_context: GameContext = null
var _presenter: IDialoguePresenter = null
var _entry_label: String = ""
var _current_step: ConversationStep = null


func start(
	compiled: CompiledDialogue,
	entry: String,
	context: GameContext,
	presenter: IDialoguePresenter
) -> bool:
	if _phase != ConversationPhase.Phase.Idle:
		push_warning("ConversationController.start() called while conversation is already active.")
		return false
	if compiled == null:
		push_warning("ConversationController.start() requires a CompiledDialogue.")
		return false
	if context == null:
		push_warning("ConversationController.start() requires a GameContext.")
		return false
	if presenter == null:
		push_warning("ConversationController.start() requires an IDialoguePresenter.")
		return false
	_compiled = compiled
	_game_context = context
	_presenter = presenter
	_entry_label = entry
	_runner = DialogueRunner.new()
	_runner.load(compiled)
	_runner.set_game_context(context)
	_runner.init_from_title(entry)
	_apply_transition(ConversationPhaseTransitions.Event.START)
	_deliver_first_step()
	return true


func notify_presentation_finished() -> void:
	if _current_step == null or _current_step.kind != ConversationStepKind.Kind.LINE:
		return
	_apply_transition(ConversationPhaseTransitions.Event.NOTIFY_PRESENTATION_FINISHED)


func cancel() -> void:
	if _phase == ConversationPhase.Phase.Idle:
		return
	var presenter_ref: IDialoguePresenter = _presenter
	var runner_ref: DialogueRunner = _runner
	_apply_transition(ConversationPhaseTransitions.Event.CANCEL)
	if presenter_ref != null:
		presenter_ref.dismiss()
	if runner_ref != null:
		runner_ref.set_cursor("")
	conversation_cancelled.emit()
	_cleanup_after_ended()


func get_debug_state() -> Dictionary:
	var line_id: String = ""
	var step_kind: ConversationStepKind.Kind = ConversationStepKind.Kind.END
	if _runner != null:
		line_id = _runner.get_cursor_line_id()
		step_kind = _runner.peek_step_kind()
	elif _current_step != null:
		line_id = _current_step.line_id
		step_kind = _current_step.kind
	var resource_path: String = ""
	if _compiled != null:
		resource_path = _compiled.source_path
	return {
		"phase": _phase,
		"line_id": line_id,
		"entry_label": _entry_label,
		"resource_path": resource_path,
		"step_kind": step_kind,
	}


func _deliver_first_step() -> void:
	var step: ConversationStep = _runner.next_step()
	_handle_yielded_step(step)


func _handle_yielded_step(step: ConversationStep) -> void:
	if step == null:
		_finish_conversation()
		return
	if step.kind == ConversationStepKind.Kind.END:
		_finish_conversation()
		return
	_current_step = step
	step_ready.emit(step)
	_presenter.present(step)


func _finish_conversation() -> void:
	var compiled_ref: CompiledDialogue = _compiled
	_apply_transition(ConversationPhaseTransitions.Event.CONVERSATION_END)
	_clear_conversation_refs()
	if compiled_ref != null:
		conversation_ended.emit(compiled_ref)
	_cleanup_after_ended()


func _emit_command_executed(command_name: String, args: Array) -> void:
	command_executed.emit(command_name, args)


func _apply_transition(event: ConversationPhaseTransitions.Event) -> void:
	_phase = ConversationPhaseTransitions.resolve(_phase, event)


func _cleanup_after_ended() -> void:
	_apply_transition(ConversationPhaseTransitions.Event.CLEANUP_TO_IDLE)


func _clear_conversation_refs() -> void:
	_current_step = null
	_runner = null
	_compiled = null
	_game_context = null
	_presenter = null
	_entry_label = ""
