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
	_phase = ConversationPhase.Phase.PresentingLine
	_deliver_first_step()
	return true


func notify_presentation_finished() -> void:
	if _phase != ConversationPhase.Phase.PresentingLine:
		return
	if _current_step == null or _current_step.kind != ConversationStepKind.Kind.LINE:
		return
	_phase = ConversationPhase.Phase.AwaitingInput


func cancel() -> void:
	if _phase == ConversationPhase.Phase.Idle:
		return
	var presenter_ref: IDialoguePresenter = _presenter
	var runner_ref: DialogueRunner = _runner
	_phase = ConversationPhase.Phase.Ended
	if presenter_ref != null:
		presenter_ref.dismiss()
	if runner_ref != null:
		runner_ref.set_cursor("")
	conversation_cancelled.emit()
	_reset_state()


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
	_reset_state()
	if compiled_ref != null:
		conversation_ended.emit(compiled_ref)


func _emit_command_executed(command_name: String, args: Array) -> void:
	command_executed.emit(command_name, args)


func _reset_state() -> void:
	_phase = ConversationPhase.Phase.Idle
	_current_step = null
	_runner = null
	_compiled = null
	_game_context = null
	_presenter = null
	_entry_label = ""
