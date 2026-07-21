extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"
const RESUME_SAVE_PATH := "user://resume_test_compiled.tres"


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


func _dialogue_line_id(compiled: CompiledDialogue) -> String:
	var title_line_id: String = compiled.get_title_line_id("start")
	return String(compiled.get_line(title_line_id).get(CompiledLine.KEY_NEXT_ID, ""))


func _save_compiled(compiled: CompiledDialogue) -> String:
	compiled.resource_uid = RESUME_SAVE_PATH
	assert_eq(ResourceSaver.save(compiled, RESUME_SAVE_PATH), OK)
	return RESUME_SAVE_PATH


func _snapshot_at_awaiting_input(controller: Node, save_path: String) -> DialogueSnapshot:
	controller.notify_presentation_finished()
	var snapshot := DialogueSnapshot.new()
	snapshot.resource_uid = save_path
	snapshot.line_id = String(controller.get_debug_state()["line_id"])
	snapshot.entry_label = "start"
	return snapshot


func test_resume_advance_continues_after_resumed_line() -> void:
	var compiled: CompiledDialogue = DialogueCompiler.compile_string(
		"~ start\nRoll: First.\nRoll: Second.\n=> END\n",
		"res://test/resume_advance_continue.dlg"
	)["compiled"]
	var save_path: String = _save_compiled(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	var snapshot: DialogueSnapshot = _snapshot_at_awaiting_input(controller, save_path)
	controller.cancel()
	presenter.present_call_count = 0
	controller.resume(snapshot, context, presenter)
	assert_eq(presenter.present_call_count, 1)
	assert_eq(presenter.last_step.text, "First.")
	controller.notify_presentation_finished()
	controller.advance()
	assert_eq(presenter.present_call_count, 2)
	assert_eq(presenter.last_step.text, "Second.")
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.PresentingLine)


func test_resume_final_line_advances_to_end() -> void:
	var compiled: CompiledDialogue = DialogueCompiler.compile_string(
		"~ start\nRoll: Only line.\n=> END\n",
		"res://test/resume_final_line.dlg"
	)["compiled"]
	var save_path: String = _save_compiled(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	var snapshot: DialogueSnapshot = _snapshot_at_awaiting_input(controller, save_path)
	controller.cancel()
	presenter.present_call_count = 0
	controller.resume(snapshot, context, presenter)
	assert_eq(presenter.present_call_count, 1)
	assert_eq(presenter.last_step.text, "Only line.")
	controller.notify_presentation_finished()
	controller.advance()
	assert_signal_emitted(controller, "conversation_ended")
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)
	assert_eq(presenter.present_call_count, 1)


func test_resume_represents_line_from_beginning() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var save_path: String = _save_compiled(compiled)
	var line_id: String = _dialogue_line_id(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	var snapshot: DialogueSnapshot = DialogueSnapshot.new()
	snapshot.resource_uid = save_path
	snapshot.line_id = controller.get_debug_state()["line_id"]
	snapshot.entry_label = "start"
	controller.cancel()
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)
	presenter.present_call_count = 0
	controller.resume(snapshot, context, presenter)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.PresentingLine)
	assert_eq(presenter.present_call_count, 1)
	assert_not_null(presenter.last_step)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(presenter.last_step.text, "Hello there.")
	assert_eq(presenter.last_step.line_id, line_id)


func test_resume_rejects_invalid_snapshot_line_id() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var save_path: String = _save_compiled(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var snapshot: DialogueSnapshot = DialogueSnapshot.new()
	snapshot.resource_uid = save_path
	snapshot.line_id = "missing_line_id"
	snapshot.entry_label = "start"
	controller.resume(snapshot, context, presenter)
	assert_push_error("valid LINE snapshot.line_id")
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)
	assert_eq(presenter.present_call_count, 0)


func test_resume_noop_when_conversation_active() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var save_path: String = _save_compiled(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	var snapshot: DialogueSnapshot = DialogueSnapshot.new()
	snapshot.resource_uid = save_path
	snapshot.line_id = _dialogue_line_id(compiled)
	snapshot.entry_label = "start"
	controller.resume(snapshot, context, presenter)
	assert_push_warning("requires Idle phase")
	assert_eq(presenter.present_call_count, 1)


func test_resume_uses_active_locale_at_resume_time() -> void:
	var compiled: CompiledDialogue = _compile_i18n_fixture()
	var save_path: String = _save_compiled(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	var snapshot: DialogueSnapshot = _snapshot_at_awaiting_input(controller, save_path)
	controller.cancel()
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message("greet_key", "Bonjour.")
	TranslationServer.add_translation(translation)
	TranslationServer.set_locale("fr")
	presenter.present_call_count = 0
	controller.resume(snapshot, context, presenter)
	assert_eq(presenter.present_call_count, 1)
	assert_eq(presenter.last_step.text, "Bonjour.")


func _compile_i18n_fixture() -> CompiledDialogue:
	var source_text: String = (
		"~ start\n"
		+ "[id:greet_key] Roll: Hello there.\n"
		+ "=> END\n"
	)
	var result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://addons/dialogue_framework/tests/fixtures/i18n_resume.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]
