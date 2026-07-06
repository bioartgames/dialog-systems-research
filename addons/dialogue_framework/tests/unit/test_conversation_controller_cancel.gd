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


func test_cancel_dismisses_presenter_and_emits_conversation_cancelled() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.cancel()
	assert_eq(presenter.dismiss_call_count, 1)
	assert_signal_emitted(controller, "conversation_cancelled")
	assert_eq(controller._phase, ConversationPhase.Phase.Idle)


func test_cancel_allows_new_start_after_cleanup() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.cancel()
	assert_true(controller.start(compiled, "start", context, presenter))


func test_cancel_clears_runner_cursor_before_reset() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	assert_false(runner.get_cursor_line_id().is_empty())
	runner.set_cursor("")
	assert_true(runner.get_cursor_line_id().is_empty())
