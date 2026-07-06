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


func test_wait_auto_advances_without_presenter() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\n@wait 0.05\nRoll: After wait.\n",
		"res://test/wait_controller.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(presenter.present_call_count, 0)
	await get_tree().create_timer(0.1).timeout
	assert_eq(presenter.present_call_count, 1)
	assert_eq(presenter.last_step.text, "After wait.")
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.LINE)


func test_wait_from_advance_also_skips_presenter() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\nRoll: Before wait.\n@wait 0.05\nRoll: After wait.\n",
		"res://test/wait_after_line.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	assert_eq(presenter.present_call_count, 1)
	await get_tree().create_timer(0.1).timeout
	assert_eq(presenter.present_call_count, 2)
	assert_eq(presenter.last_step.text, "After wait.")
