extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func _compile_fixture(path: String = FIXTURE_PATH) -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(path)
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


func test_notify_presentation_finished_transitions_line_to_awaiting_input() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(controller._phase, ConversationPhase.Phase.PresentingLine)
	controller.notify_presentation_finished()
	assert_eq(controller._phase, ConversationPhase.Phase.AwaitingInput)


func test_notify_presentation_finished_noop_when_not_presenting_line() -> void:
	var controller: Node = _new_controller()
	controller.notify_presentation_finished()
	assert_eq(controller._phase, ConversationPhase.Phase.Idle)


func test_notify_presentation_finished_noop_after_awaiting_input() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.notify_presentation_finished()
	assert_eq(controller._phase, ConversationPhase.Phase.AwaitingInput)
