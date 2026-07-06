extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func _compile_fixture(path: String = FIXTURE_PATH) -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(path)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


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


func _advance_to_choices(controller: Node) -> void:
	controller.notify_presentation_finished()
	controller.advance()


func test_choose_requires_awaiting_choice_phase() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.choose(0)
	assert_eq(presenter.present_call_count, 1)


func test_choose_advances_to_selected_target_line() -> void:
	var compiled: CompiledDialogue = _compile(
		(
			"~ start\n"
			+ "Roll: Pick one.\n"
			+ "- Continue => more\n"
			+ "\n"
			+ "~ more\n"
			+ "Roll: You chose continue.\n"
		),
		"res://test/choose_target.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	_advance_to_choices(controller)
	assert_eq(controller._phase, ConversationPhase.Phase.AwaitingChoice)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	controller.choose(0)
	assert_eq(controller._phase, ConversationPhase.Phase.PresentingLine)
	assert_eq(presenter.present_call_count, 3)
	assert_eq(presenter.last_step.text, "You chose continue.")
