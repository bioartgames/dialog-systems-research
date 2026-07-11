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


func _signal_argument_types(controller: Node, signal_name: String) -> Array:
	for signal_info: Dictionary in controller.get_signal_list():
		if String(signal_info.get("name", "")) == signal_name:
			return signal_info.get("args", [])
	return []


func test_declares_all_controller_signals_with_expected_payloads() -> void:
	var controller: Node = _new_controller()
	var signal_names: PackedStringArray = PackedStringArray()
	for signal_info: Dictionary in controller.get_signal_list():
		signal_names.append(String(signal_info.get("name", "")))
	assert_true(signal_names.has("step_ready"))
	assert_true(signal_names.has("conversation_ended"))
	assert_true(signal_names.has("conversation_cancelled"))
	assert_true(signal_names.has("command_executed"))
	assert_eq(_signal_argument_types(controller, "step_ready").size(), 1)
	assert_eq(_signal_argument_types(controller, "conversation_ended").size(), 1)
	assert_eq(_signal_argument_types(controller, "conversation_cancelled").size(), 0)
	assert_eq(_signal_argument_types(controller, "command_executed").size(), 2)


func test_conversation_ended_emits_when_start_hits_end_node() -> void:
	var source_text: String = "~ start\n=> END\n"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/end_controller.dlg"
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
	var compiled: CompiledDialogue = compile_result["compiled"]
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_signal_emitted(controller, "conversation_ended")
	assert_eq(presenter.dismiss_call_count, 1)


func test_natural_end_dismisses_presenter_after_final_line_accept() -> void:
	var source_text: String = "~ start\nRoll: Bye.\n=> END\n"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/natural_end_dismiss.dlg"
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
	var compiled: CompiledDialogue = compile_result["compiled"]
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(presenter.present_call_count, 1)
	controller.notify_presentation_finished()
	controller.advance()
	assert_signal_emitted(controller, "conversation_ended")
	assert_eq(presenter.dismiss_call_count, 1)
	assert_eq(
		controller.get_debug_state()["phase"],
		ConversationPhase.Phase.Idle
	)


func test_command_executed_emits_from_command_completion_hook() -> void:
	var controller: Node = _new_controller()
	watch_signals(controller)
	controller.call("_emit_command_executed", "emit", PackedStringArray(["quest_done"]))
	assert_signal_emitted(controller, "command_executed")
