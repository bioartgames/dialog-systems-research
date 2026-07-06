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
var _wait_generation: int = 0


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
	_progress_to_next_step()
	return true


func advance() -> void:
	if _phase != ConversationPhase.Phase.AwaitingInput:
		push_warning("ConversationController.advance() requires AwaitingInput phase.")
		return
	_progress_to_next_step()


func choose(option_index: int) -> void:
	if _phase != ConversationPhase.Phase.AwaitingChoice:
		push_warning("ConversationController.choose() requires AwaitingChoice phase.")
		return
	if _current_step == null or _current_step.kind != ConversationStepKind.Kind.CHOICES:
		push_warning("ConversationController.choose() requires an active CHOICES step.")
		return
	if option_index < 0 or option_index >= _current_step.options.size():
		push_warning("ConversationController.choose() received invalid option index %d." % option_index)
		return
	var target_line_id: String = String(_current_step.options[option_index].get("target_line_id", ""))
	if target_line_id.is_empty():
		push_warning("ConversationController.choose() option has no target_line_id.")
		return
	_runner.set_cursor(target_line_id)
	_apply_transition(ConversationPhaseTransitions.Event.CHOOSE)
	_progress_to_next_step()


func notify_presentation_finished() -> void:
	if _phase != ConversationPhase.Phase.PresentingLine:
		return
	if _current_step == null or _current_step.kind != ConversationStepKind.Kind.LINE:
		return
	_apply_transition(ConversationPhaseTransitions.Event.NOTIFY_PRESENTATION_FINISHED)


func cancel() -> void:
	if _phase == ConversationPhase.Phase.Idle:
		return
	_bump_wait_generation()
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


func _progress_to_next_step() -> void:
	if _runner == null:
		return
	var step: ConversationStep = _runner.next_step()
	_deliver_step(step)


func _deliver_step(step: ConversationStep) -> void:
	if step == null:
		_finish_conversation()
		return
	match step.kind:
		ConversationStepKind.Kind.END:
			_finish_conversation()
		ConversationStepKind.Kind.LINE:
			_deliver_presented_step(step, ConversationPhaseTransitions.Event.ADVANCE_LINE)
		ConversationStepKind.Kind.CHOICES:
			_deliver_choices_step(step)
		ConversationStepKind.Kind.WAIT:
			_deliver_wait_step(step)
		ConversationStepKind.Kind.COMMAND:
			_deliver_command_step(step)
		_:
			_finish_conversation()


func _deliver_presented_step(
	step: ConversationStep,
	transition_event: ConversationPhaseTransitions.Event
) -> void:
	if _phase == ConversationPhase.Phase.AwaitingInput:
		_apply_transition(transition_event)
	_current_step = step
	step_ready.emit(step)
	_presenter.present(step)


func _deliver_choices_step(step: ConversationStep) -> void:
	if step.options.is_empty():
		_handle_zero_visible_choices(step)
		return
	if _phase == ConversationPhase.Phase.AwaitingInput:
		_apply_transition(ConversationPhaseTransitions.Event.ADVANCE_CHOICES)
	_current_step = step
	step_ready.emit(step)
	_presenter.present(step)


func _handle_zero_visible_choices(step: ConversationStep) -> void:
	assert(
		step.options.is_empty(),
		"D6.10 debug assert: CHOICES step has zero visible options."
	)
	var message: String = "CHOICES step has zero visible options (D6.10)."
	push_error("ConversationController: %s" % message)
	_finish_conversation()


func _deliver_wait_step(step: ConversationStep) -> void:
	_current_step = step
	_start_wait_timer(step.duration_seconds)


func _deliver_command_step(step: ConversationStep) -> void:
	if _phase == ConversationPhase.Phase.AwaitingInput:
		_apply_transition(ConversationPhaseTransitions.Event.ADVANCE_COMMAND)
	_current_step = step


func _start_wait_timer(duration_seconds: float) -> void:
	_bump_wait_generation()
	var generation: int = _wait_generation
	var timer: SceneTreeTimer = get_tree().create_timer(maxf(duration_seconds, 0.0))
	timer.timeout.connect(
		func() -> void:
			_on_wait_timer_finished(generation),
		CONNECT_ONE_SHOT
	)


func _on_wait_timer_finished(generation: int) -> void:
	if generation != _wait_generation:
		return
	if _phase == ConversationPhase.Phase.Idle or _phase == ConversationPhase.Phase.Ended:
		return
	_progress_to_next_step()


func _finish_conversation() -> void:
	var compiled_ref: CompiledDialogue = _compiled
	_bump_wait_generation()
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


func _bump_wait_generation() -> void:
	_wait_generation += 1


func _clear_conversation_refs() -> void:
	_current_step = null
	_runner = null
	_compiled = null
	_game_context = null
	_presenter = null
	_entry_label = ""
