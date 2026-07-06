extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"


func _compile(source_text: String, path: String) -> CompiledDialogue:
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _mock_context() -> GameContext:
	return load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()


func _mock_presenter() -> IDialoguePresenter:
	var presenter: IDialoguePresenter = load(
		"res://addons/dialogue_framework/tests/helpers/mock_dialogue_presenter.gd"
	).new()
	add_child_autofree(presenter)
	return presenter


func _new_controller() -> Node:
	var controller: Node = load(CONTROLLER_PATH).new()
	add_child_autofree(controller)
	return controller


func test_advance_presents_next_line_after_notify() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\nRoll: First line.\nRoll: Second line.\n",
		"res://test/two_lines.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(presenter.last_step.text, "First line.")
	controller.notify_presentation_finished()
	assert_eq(controller._phase, ConversationPhase.Phase.AwaitingInput)
	controller.advance()
	assert_eq(controller._phase, ConversationPhase.Phase.PresentingLine)
	assert_eq(presenter.last_step.text, "Second line.")
	assert_eq(presenter.present_call_count, 2)


func test_advance_requires_awaiting_input_phase() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\nRoll: Hello.\n",
		"res://test/single_line.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.advance()
	assert_eq(presenter.present_call_count, 1)


func test_step_ready_emitted_before_present_on_advance() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\nRoll: First line.\nRoll: Second line.\n",
		"res://test/step_ready_order.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	watch_signals(controller)
	controller.advance()
	assert_signal_emitted(controller, "step_ready")
	assert_eq(presenter.last_step.text, "Second line.")
