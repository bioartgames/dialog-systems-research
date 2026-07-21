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
var _prompting_line_id: String = ""
var _wait_generation: int = 0
var _command_generation: int = 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_on_translation_changed()


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


func resume(snapshot: DialogueSnapshot, context: GameContext, presenter: IDialoguePresenter) -> void:
	if _phase != ConversationPhase.Phase.Idle:
		push_warning("ConversationController.resume() requires Idle phase.")
		return
	if snapshot == null:
		push_warning("ConversationController.resume() requires a DialogueSnapshot.")
		return
	if context == null:
		push_warning("ConversationController.resume() requires a GameContext.")
		return
	if presenter == null:
		push_warning("ConversationController.resume() requires an IDialoguePresenter.")
		return
	var compiled: CompiledDialogue = _load_compiled_dialogue(snapshot.resource_uid)
	if compiled == null:
		push_error(
			"ConversationController.resume() could not load CompiledDialogue for '%s'."
			% snapshot.resource_uid
		)
		return
	if not _is_snapshot_line_id_valid(compiled, snapshot.line_id):
		push_error(
			"ConversationController.resume() requires a valid LINE snapshot.line_id (D12.4)."
		)
		return
	_compiled = compiled
	_game_context = context
	_presenter = presenter
	_entry_label = snapshot.entry_label
	_runner = DialogueRunner.new()
	_runner.load(compiled)
	_runner.set_game_context(context)
	_runner.set_cursor(snapshot.line_id)
	_apply_transition(ConversationPhaseTransitions.Event.START)
	var step: ConversationStep = _runner.next_step()
	if step == null or step.kind != ConversationStepKind.Kind.LINE:
		push_error("ConversationController.resume() could not rebuild LINE step.")
		_clear_conversation_refs()
		_apply_transition(ConversationPhaseTransitions.Event.CLEANUP_TO_IDLE)
		return
	_deliver_resumed_line_step(step)


func advance() -> void:
	if _phase != ConversationPhase.Phase.AwaitingInput:
		push_warning("ConversationController.advance() requires AwaitingInput phase.")
		return
	if _current_step == null or _current_step.kind != ConversationStepKind.Kind.LINE:
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
	_bump_command_generation()
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
	if _current_step != null:
		line_id = _current_step.line_id
		step_kind = _current_step.kind
	elif _runner != null:
		line_id = _runner.get_cursor_line_id()
		step_kind = _runner.peek_step_kind()
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
	var cursor_before: String = _runner.get_cursor_line_id()
	var step: ConversationStep = _runner.next_step()
	if step == null:
		if not cursor_before.is_empty():
			_handle_invalid_cursor(cursor_before)
		else:
			_finish_conversation()
		return
	_deliver_step(step)


func _deliver_step(step: ConversationStep) -> void:
	if step == null:
		_finish_conversation()
		return
	_trace_step_delivery(step)
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


func _deliver_resumed_line_step(step: ConversationStep) -> void:
	_current_step = step
	_prompting_line_id = step.line_id
	_trace_step_delivery(step, "resume")
	step_ready.emit(step)
	_presenter.present(step)


func _on_translation_changed() -> void:
	match _phase:
		ConversationPhase.Phase.PresentingLine, ConversationPhase.Phase.AwaitingInput:
			if _current_step == null or _current_step.kind != ConversationStepKind.Kind.LINE:
				return
			var line_step: ConversationStep = _rebuild_line_step(_current_step.line_id)
			if line_step == null:
				return
			_current_step = line_step
			_trace_step_delivery(line_step, "translation_refresh")
			_presenter.present(line_step)
		ConversationPhase.Phase.AwaitingChoice:
			if _current_step == null or _current_step.kind != ConversationStepKind.Kind.CHOICES:
				return
			if not _prompting_line_id.is_empty():
				var prompting_line: ConversationStep = _rebuild_line_step(_prompting_line_id)
				if prompting_line != null:
					_trace_step_delivery(prompting_line, "translation_refresh_prompt")
					_presenter.refresh_line_text(prompting_line)
			var choices_step: ConversationStep = _rebuild_choices_step(_current_step.line_id)
			if choices_step == null:
				return
			_current_step = choices_step
			_trace_step_delivery(choices_step, "translation_refresh")
			_presenter.present(choices_step)
		_:
			return


func _rebuild_line_step(line_id: String) -> ConversationStep:
	if _compiled == null or _game_context == null or line_id.is_empty():
		return null
	var line: Dictionary = _compiled.get_line(line_id)
	if line.is_empty() or CompiledLine.get_kind(line) != LineKind.Kind.LINE:
		return null
	return LineStepBuilder.build(line, line_id, _game_context)


func _rebuild_choices_step(first_choice_line_id: String) -> ConversationStep:
	if _runner == null:
		return null
	return _runner.build_choices_step_at_line_id(first_choice_line_id)


func _load_compiled_dialogue(resource_uid: String) -> CompiledDialogue:
	if resource_uid.is_empty():
		return null
	if not ResourceLoader.exists(resource_uid):
		return null
	var resource: Resource = load(resource_uid)
	if resource is CompiledDialogue:
		return resource as CompiledDialogue
	return null


func _is_snapshot_line_id_valid(compiled: CompiledDialogue, line_id: String) -> bool:
	if line_id.is_empty() or compiled == null:
		return false
	var line: Dictionary = compiled.get_line(line_id)
	if line.is_empty():
		return false
	return CompiledLine.get_kind(line) == LineKind.Kind.LINE


func _is_debug_trace_enabled() -> bool:
	return OS.is_debug_build()


func _trace_step_delivery(step: ConversationStep, action: String = "deliver") -> void:
	if not _is_debug_trace_enabled():
		return
	print(
		"[DialogueFramework] step_%s line_id=%s kind=%s phase=%s entry=%s resource=%s"
		% [
			action,
			step.line_id,
			step.kind,
			_phase,
			_entry_label,
			_compiled.source_path if _compiled != null else "",
		]
	)


func _deliver_presented_step(
	step: ConversationStep,
	transition_event: ConversationPhaseTransitions.Event
) -> void:
	if (
		_phase == ConversationPhase.Phase.AwaitingInput
		or _phase == ConversationPhase.Phase.ExecutingCommand
	):
		_apply_transition(transition_event)
	_current_step = step
	if step.kind == ConversationStepKind.Kind.LINE:
		_prompting_line_id = step.line_id
	step_ready.emit(step)
	_presenter.present(step)


func _deliver_choices_step(step: ConversationStep) -> void:
	if step.options.is_empty():
		_handle_zero_visible_choices(step)
		return
	if (
		_phase == ConversationPhase.Phase.AwaitingInput
		or _phase == ConversationPhase.Phase.ExecutingCommand
	):
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
	push_warning("ConversationController: %s" % message)
	_finish_conversation()


func _deliver_wait_step(step: ConversationStep) -> void:
	_current_step = step
	_start_wait_timer(step.duration_seconds)


func _deliver_command_step(step: ConversationStep) -> void:
	_current_step = step
	_run_command_sequence(step)


func _run_command_sequence(step: ConversationStep) -> void:
	_bump_command_generation()
	var generation: int = _command_generation
	_begin_command_execution()
	if generation != _command_generation:
		return
	await _execute_command(step)
	if generation != _command_generation:
		return
	if _phase == ConversationPhase.Phase.Idle or _phase == ConversationPhase.Phase.Ended:
		return
	if step.command_name != "emit":
		_emit_command_executed(step.command_name, _args_tokens_to_array(step.args_tokens))
	_progress_to_next_step()


func _begin_command_execution() -> void:
	var dismiss_presenter: bool = _should_dismiss_presenter_before_command()
	if _phase == ConversationPhase.Phase.PresentingLine:
		_apply_transition(ConversationPhaseTransitions.Event.NOTIFY_PRESENTATION_FINISHED)
	if _phase == ConversationPhase.Phase.AwaitingInput:
		_apply_transition(ConversationPhaseTransitions.Event.ADVANCE_COMMAND)
	elif _phase == ConversationPhase.Phase.ExecutingCommand:
		_apply_transition(ConversationPhaseTransitions.Event.ADVANCE_COMMAND)
	if dismiss_presenter and _presenter != null:
		_presenter.dismiss()


func _should_dismiss_presenter_before_command() -> bool:
	if _phase != ConversationPhase.Phase.AwaitingInput:
		return false
	if _current_step == null or _current_step.kind != ConversationStepKind.Kind.COMMAND:
		return false
	return not BuiltInCommandHandlers.is_non_visual_builtin(_current_step.command_name)


func _execute_command(step: ConversationStep) -> void:
	match step.command_name:
		"set_flag":
			BuiltInCommandHandlers.handle_set_flag(_game_context, step.args_tokens)
		"emit":
			BuiltInCommandHandlers.handle_emit(step.args_tokens, _emit_command_executed)
		_:
			if CommandRegistry.has_command(step.command_name):
				await CommandRegistry.dispatch(
					step.command_name,
					_args_tokens_to_packed_string_array(step.args_tokens)
				)
			else:
				push_error(
					"ConversationController encountered unregistered command '%s'."
					% step.command_name
				)


func _args_tokens_to_array(args_tokens: Array) -> Array:
	var args: Array = []
	for token: Variant in args_tokens:
		if token is Dictionary:
			args.append(_arg_token_value(token))
	return args


func _args_tokens_to_packed_string_array(args_tokens: Array) -> PackedStringArray:
	var packed: PackedStringArray = PackedStringArray()
	for arg: Variant in _args_tokens_to_array(args_tokens):
		packed.append(str(arg))
	return packed


func _arg_token_value(token: Dictionary) -> Variant:
	match String(token.get("type", "")):
		CommandArgumentTokenizer.TYPE_BOOL:
			return bool(token.get("value", false))
		CommandArgumentTokenizer.TYPE_INT:
			return int(token.get("value", 0))
		CommandArgumentTokenizer.TYPE_FLOAT:
			return float(token.get("value", 0.0))
		CommandArgumentTokenizer.TYPE_STRING:
			return String(token.get("value", ""))
		_:
			return token.get("value")


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
	var presenter_ref: IDialoguePresenter = _presenter
	_bump_wait_generation()
	_bump_command_generation()
	_apply_transition(ConversationPhaseTransitions.Event.CONVERSATION_END)
	if presenter_ref != null:
		presenter_ref.dismiss()
	_clear_conversation_refs()
	if compiled_ref != null:
		conversation_ended.emit(compiled_ref)
	_cleanup_after_ended()


func _handle_invalid_cursor(invalid_line_id: String) -> void:
	var resource_path: String = ""
	if _compiled != null:
		resource_path = _compiled.source_path
	push_error(
		"Invalid dialogue cursor line_id='%s' resource_path='%s' (D15.2)."
		% [invalid_line_id, resource_path]
	)
	if _presenter != null:
		_presenter.dismiss()
	_finish_conversation()


func _emit_command_executed(command_name: String, args: Array) -> void:
	command_executed.emit(command_name, args)


func _apply_transition(event: ConversationPhaseTransitions.Event) -> void:
	_phase = ConversationPhaseTransitions.resolve(_phase, event)


func _cleanup_after_ended() -> void:
	_apply_transition(ConversationPhaseTransitions.Event.CLEANUP_TO_IDLE)


func _bump_wait_generation() -> void:
	_wait_generation += 1


func _bump_command_generation() -> void:
	_command_generation += 1


func _clear_conversation_refs() -> void:
	_current_step = null
	_prompting_line_id = ""
	_runner = null
	_compiled = null
	_game_context = null
	_presenter = null
	_entry_label = ""
