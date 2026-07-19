extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func before_each() -> void:
	TranslationServer.set_locale("en")


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


func _add_french_greeting_translation() -> void:
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message("greet_key", "Bonjour.")
	TranslationServer.add_translation(translation)


func _add_french_choice_translation(choice_key: String) -> void:
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message(choice_key, "Acheter")
	TranslationServer.add_translation(translation)


func test_translation_change_represents_line_in_presenting_phase() -> void:
	var compiled: CompiledDialogue = _compile_i18n_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	_add_french_greeting_translation()
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(presenter.last_step.text, "Hello there.")
	TranslationServer.set_locale("fr")
	assert_eq(presenter.present_call_count, 2)
	assert_eq(presenter.last_step.text, "Bonjour.")


func test_translation_change_represents_line_in_awaiting_input_phase() -> void:
	var compiled: CompiledDialogue = _compile_i18n_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	_add_french_greeting_translation()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingInput)
	TranslationServer.set_locale("fr")
	assert_eq(presenter.present_call_count, 2)
	assert_eq(presenter.last_step.text, "Bonjour.")


func test_translation_change_ignored_when_idle() -> void:
	var compiled: CompiledDialogue = _compile_i18n_fixture()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	_add_french_greeting_translation()
	var source_text: String = "~ start\n=> END\n"
	var end_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/end_translation.dlg"
	)
	var end_compiled: CompiledDialogue = end_result["compiled"]
	assert_true(controller.start(end_compiled, "start", context, presenter))
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)
	var calls_before: int = presenter.present_call_count
	TranslationServer.set_locale("fr")
	assert_eq(presenter.present_call_count, calls_before)


func test_translation_change_represents_choices_in_awaiting_choice_phase() -> void:
	var source_path: String = (
		"res://addons/dialogue_framework/tests/fixtures/i18n_choices_refresh.dlg"
	)
	var source_text: String = (
		"~ start\n"
		+ "Roll: Choose.\n"
		+ "- Buy => end\n"
		+ "~ end\n"
		+ "Roll: Done.\n"
		+ "=> END\n"
	)
	var result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		source_path
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var compiled: CompiledDialogue = result["compiled"]
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	_add_french_choice_translation("%s::3" % source_path)
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(String(presenter.last_step.options[0]["text"]), "Buy")
	var calls_before: int = presenter.present_call_count
	TranslationServer.set_locale("fr")
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)
	# refresh_line_text() updates the preceding LINE in-place; present() is called once for CHOICES.
	assert_eq(presenter.refresh_line_text_call_count, 1)
	assert_eq(presenter.last_refresh_step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(presenter.present_call_count, calls_before + 1)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(String(presenter.last_step.options[0]["text"]), "Acheter")
