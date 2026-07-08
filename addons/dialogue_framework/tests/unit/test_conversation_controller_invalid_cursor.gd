extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const RESOURCE_PATH := "res://test/invalid_cursor_runtime.dlg"


func _compile(source_text: String) -> CompiledDialogue:
	var result: Dictionary = DialogueCompiler.compile_string(source_text, RESOURCE_PATH)
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


func _break_next_id(compiled: CompiledDialogue) -> String:
	var title_line_id: String = compiled.get_title_line_id("start")
	var dialogue_line_id: String = String(
		compiled.get_line(title_line_id).get(CompiledLine.KEY_NEXT_ID, "")
	)
	const BROKEN_NEXT_ID := "missing_runtime_line_id"
	compiled.lines[dialogue_line_id][CompiledLine.KEY_NEXT_ID] = BROKEN_NEXT_ID
	return BROKEN_NEXT_ID


func test_invalid_cursor_ends_gracefully_with_error_dismiss_and_signal() -> void:
	var compiled: CompiledDialogue = _compile("~ start\nRoll: Hello.\n=> END\n")
	var broken_line_id: String = _break_next_id(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(presenter.present_call_count, 1)
	controller.notify_presentation_finished()
	controller.advance()
	assert_push_error(
		"Invalid dialogue cursor line_id='%s' resource_path='%s' (D15.2)."
		% [broken_line_id, compiled.source_path]
	)
	assert_signal_emitted(controller, "conversation_ended")
	assert_eq(presenter.dismiss_call_count, 1)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)


func test_choose_to_missing_line_id_ends_gracefully() -> void:
	var compiled: CompiledDialogue = _compile(
		(
			"~ start\n"
			+ "Roll: Pick one.\n"
			+ "- Go => path_a\n"
			+ "\n"
			+ "~ path_a\n"
			+ "Roll: Path A.\n"
		)
	)
	var choice_line_id: String = ""
	for line_id: String in compiled.lines:
		if CompiledLine.get_kind(compiled.lines[line_id]) == LineKind.Kind.CHOICE:
			choice_line_id = line_id
			break
	assert_false(choice_line_id.is_empty())
	const MISSING_TARGET := "missing_choice_target"
	compiled.lines[choice_line_id][CompiledLine.KEY_TARGET_LINE_ID] = MISSING_TARGET
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	controller.choose(0)
	assert_push_error(
		"Invalid dialogue cursor line_id='%s' resource_path='%s' (D15.2)."
		% [MISSING_TARGET, compiled.source_path]
	)
	assert_signal_emitted(controller, "conversation_ended")
	assert_eq(presenter.dismiss_call_count, 1)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)
