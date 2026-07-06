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


func test_get_debug_state_exposes_required_keys() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	var debug_state: Dictionary = controller.get_debug_state()
	assert_true(debug_state.has("phase"))
	assert_true(debug_state.has("line_id"))
	assert_true(debug_state.has("entry_label"))
	assert_true(debug_state.has("resource_path"))
	assert_true(debug_state.has("step_kind"))
	assert_eq(debug_state["entry_label"], "start")
	assert_eq(debug_state["resource_path"], FIXTURE_PATH)
	assert_eq(debug_state["phase"], ConversationPhase.Phase.PresentingLine)


func test_get_debug_state_phase_idle_after_conversation_end() -> void:
	var source_text: String = "~ start\n=> END\n"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/end_debug.dlg"
	)
	var compiled: CompiledDialogue = compile_result["compiled"]
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)
