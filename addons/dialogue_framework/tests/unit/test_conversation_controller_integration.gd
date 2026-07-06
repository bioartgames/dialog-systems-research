extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"
const RESUME_SAVE_PATH := "user://integration_resume_compiled.tres"


func before_each() -> void:
	TranslationServer.set_locale("en")


func _compile(source_text: String, path: String) -> CompiledDialogue:
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _compile_fixture(path: String = FIXTURE_PATH) -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(path)
	return _compile(source_text, path)


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


func _phase_name(controller: Node) -> int:
	return int(controller.get_debug_state()["phase"])


func _save_compiled(compiled: CompiledDialogue) -> String:
	compiled.resource_uid = RESUME_SAVE_PATH
	assert_eq(ResourceSaver.save(compiled, RESUME_SAVE_PATH), OK)
	return RESUME_SAVE_PATH


func test_integration_full_flow_phases_and_signals() -> void:
	var compiled: CompiledDialogue = _compile(
		(
			"~ start\n"
			+ "Roll: Greeting.\n"
			+ "- Continue => farewell\n"
			+ "\n"
			+ "~ farewell\n"
			+ "Roll: Farewell.\n"
			+ "=> END\n"
		),
		"res://test/integration_full_flow.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(_phase_name(controller), ConversationPhase.Phase.PresentingLine)
	assert_signal_emitted(controller, "step_ready")
	assert_eq(presenter.last_step.text, "Greeting.")
	controller.notify_presentation_finished()
	assert_eq(_phase_name(controller), ConversationPhase.Phase.AwaitingInput)
	controller.advance()
	assert_eq(_phase_name(controller), ConversationPhase.Phase.AwaitingChoice)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	controller.choose(0)
	assert_eq(_phase_name(controller), ConversationPhase.Phase.PresentingLine)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(presenter.last_step.text, "Farewell.")
	controller.notify_presentation_finished()
	assert_eq(_phase_name(controller), ConversationPhase.Phase.AwaitingInput)
	controller.advance()
	assert_eq(_phase_name(controller), ConversationPhase.Phase.Idle)
	assert_signal_emitted(controller, "conversation_ended")


func test_integration_cancel_mid_conversation() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(_phase_name(controller), ConversationPhase.Phase.PresentingLine)
	controller.cancel()
	assert_eq(_phase_name(controller), ConversationPhase.Phase.Idle)
	assert_eq(presenter.dismiss_call_count, 1)
	assert_signal_emitted(controller, "conversation_cancelled")
	assert_signal_not_emitted(controller, "conversation_ended")


func test_integration_resume_after_cancel() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var save_path: String = _save_compiled(compiled)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	var snapshot: DialogueSnapshot = DialogueSnapshot.new()
	snapshot.resource_uid = save_path
	snapshot.line_id = String(controller.get_debug_state()["line_id"])
	snapshot.entry_label = "start"
	controller.cancel()
	presenter.present_call_count = 0
	controller.resume(snapshot, context, presenter)
	assert_eq(_phase_name(controller), ConversationPhase.Phase.PresentingLine)
	assert_signal_emitted(controller, "step_ready")
	assert_eq(presenter.present_call_count, 1)
	assert_eq(presenter.last_step.text, "Hello there.")


func test_integration_translation_change_during_active_conversation() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\n[id:greet_key] Roll: Hello there.\n=> END\n",
		"res://test/integration_i18n.dlg"
	)
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message("greet_key", "Bonjour.")
	TranslationServer.add_translation(translation)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(_phase_name(controller), ConversationPhase.Phase.PresentingLine)
	assert_eq(presenter.last_step.text, "Hello there.")
	TranslationServer.set_locale("fr")
	assert_eq(_phase_name(controller), ConversationPhase.Phase.PresentingLine)
	assert_signal_emitted(controller, "step_ready")
	assert_eq(presenter.last_step.text, "Bonjour.")
