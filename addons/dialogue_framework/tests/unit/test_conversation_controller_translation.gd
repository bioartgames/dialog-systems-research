extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func before_each() -> void:
	TranslationServer.set_locale("en")
	CommandRegistry.clear_for_tests()


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
	var line_id_before: String = presenter.last_step.line_id
	TranslationServer.set_locale("fr")
	assert_eq(presenter.present_call_count, 2)
	assert_eq(presenter.last_step.text, "Bonjour.")
	assert_eq(presenter.last_step.line_id, line_id_before)


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
	var compiled: CompiledDialogue = _compile_fixture()
	var leave_key: String = "res://addons/dialogue_framework/tests/fixtures/minimal.dlg::3"
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message(leave_key, "Partir.")
	TranslationServer.add_translation(translation)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(presenter.last_step.options[0]["text"], "Leave")
	TranslationServer.set_locale("fr")
	assert_eq(presenter.present_call_count, 3)
	assert_eq(presenter.last_step.options[0]["text"], "Partir.")


func test_translation_change_preserves_choice_traversal_on_refresh() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var leave_key: String = "res://addons/dialogue_framework/tests/fixtures/minimal.dlg::3"
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message(leave_key, "Partir.")
	TranslationServer.add_translation(translation)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	var step_before: ConversationStep = presenter.last_step
	assert_eq(step_before.options[0]["text"], "Leave")
	var line_id_before: String = step_before.line_id
	var target_before: String = String(step_before.options[0]["target_line_id"])
	var index_before: int = int(step_before.options[0]["index"])
	TranslationServer.set_locale("fr")
	assert_eq(presenter.last_step.line_id, line_id_before)
	assert_eq(String(presenter.last_step.options[0]["target_line_id"]), target_before)
	assert_eq(int(presenter.last_step.options[0]["index"]), index_before)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)


func test_translation_change_refreshes_co_visible_prompting_line_during_awaiting_choice() -> void:
	var source_path: String = "res://test/co_visible_locale.dlg"
	var compiled: CompiledDialogue = DialogueCompiler.compile_string(
		(
			"~ start\n"
			+ "[id:prompt_key] Roll: Hello there.\n"
			+ "- Leave => END\n"
		),
		source_path
	)["compiled"]
	var leave_key: String = "%s::3" % source_path
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message("prompt_key", "Bonjour.")
	translation.add_message(leave_key, "Partir.")
	TranslationServer.add_translation(translation)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(presenter.last_step.options[0]["text"], "Leave")
	var target_before: String = String(presenter.last_step.options[0]["target_line_id"])
	var index_before: int = int(presenter.last_step.options[0]["index"])
	var refresh_before: int = presenter.refresh_line_text_call_count
	var present_before: int = presenter.present_call_count
	TranslationServer.set_locale("fr")
	assert_gt(presenter.refresh_line_text_call_count, refresh_before)
	assert_not_null(presenter.last_refresh_step)
	assert_eq(presenter.last_refresh_step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(presenter.last_refresh_step.text, "Bonjour.")
	assert_gt(presenter.present_call_count, present_before)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(presenter.last_step.options[0]["text"], "Partir.")
	assert_eq(String(presenter.last_step.options[0]["target_line_id"]), target_before)
	assert_eq(int(presenter.last_step.options[0]["index"]), index_before)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)
	assert_eq(controller.get_debug_state()["step_kind"], ConversationStepKind.Kind.CHOICES)


func test_translation_change_choices_refresh_safe_when_prompting_line_id_empty() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var leave_key: String = "res://addons/dialogue_framework/tests/fixtures/minimal.dlg::3"
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message(leave_key, "Partir.")
	TranslationServer.add_translation(translation)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)
	controller._prompting_line_id = ""
	var refresh_before: int = presenter.refresh_line_text_call_count
	TranslationServer.set_locale("fr")
	assert_eq(presenter.refresh_line_text_call_count, refresh_before)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(presenter.last_step.options[0]["text"], "Partir.")
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.AwaitingChoice)


func test_translation_change_ignored_during_executing_command() -> void:
	CommandRegistry.clear_for_tests()
	var manifest_path: String = "res://addons/dialogue_framework/tests/fixtures/test_command_manifest.tres"
	var setting_key: String = "dialogue_framework/command_manifest_path"
	var previous_path: Variant = ProjectSettings.get_setting(setting_key)
	ProjectSettings.set_setting(setting_key, manifest_path)
	var compiled: CompiledDialogue = DialogueCompiler.compile_string(
		"~ start\n@cutscene intro\n[id:greet_key] Roll: After cutscene.\n=> END\n",
		"res://test/locale_during_command.dlg"
	)["compiled"]
	if previous_path == null:
		ProjectSettings.set_setting(setting_key, "")
	else:
		ProjectSettings.set_setting(setting_key, previous_path)
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message("greet_key", "Bonjour.")
	TranslationServer.add_translation(translation)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var tree: SceneTree = get_tree()
	CommandRegistry.register(
		"cutscene",
		func(_args: PackedStringArray) -> void:
			await tree.create_timer(0.05).timeout
	)
	assert_true(controller.start(compiled, "start", context, presenter))
	var calls_during_command: int = presenter.present_call_count
	TranslationServer.set_locale("fr")
	assert_eq(presenter.present_call_count, calls_during_command)
	await get_tree().create_timer(0.1).timeout
	assert_eq(presenter.last_step.text, "Bonjour.")


func test_translation_change_ignored_during_wait() -> void:
	var compiled: CompiledDialogue = DialogueCompiler.compile_string(
		(
			"~ start\n"
			+ "[id:greet_key] Roll: Before wait.\n"
			+ "@wait 0.2\n"
			+ "[id:after_wait] Roll: After wait.\n"
			+ "=> END\n"
		),
		"res://test/locale_during_wait.dlg"
	)["compiled"]
	var translation: Translation = Translation.new()
	translation.locale = "fr"
	translation.add_message("greet_key", "Bonjour avant.")
	TranslationServer.add_translation(translation)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	var calls_before_wait: int = presenter.present_call_count
	controller.advance()
	TranslationServer.set_locale("fr")
	await get_tree().create_timer(0.05).timeout
	assert_eq(presenter.present_call_count, calls_before_wait)
	await get_tree().create_timer(0.2).timeout
	assert_eq(presenter.last_step.text, "After wait.")


func test_translation_change_reresolves_interpolation_on_line_refresh() -> void:
	var flag_setting: String = "dialogue_framework/flag_manifest_path"
	var previous_flag: Variant = ProjectSettings.get_setting(flag_setting)
	ProjectSettings.set_setting(
		flag_setting,
		"res://addons/dialogue_framework/tests/fixtures/test_flag_manifest.tres"
	)
	var source_text: String = (
		"~ start\n"
		+ "Roll: Hello {player_name}.\n"
		+ "=> END\n"
	)
	var result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://addons/dialogue_framework/tests/fixtures/i18n_interpolation.dlg"
	)
	if previous_flag == null:
		ProjectSettings.set_setting(flag_setting, "")
	else:
		ProjectSettings.set_setting(flag_setting, previous_flag)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var compiled: CompiledDialogue = result["compiled"]
	var context: GameContext = _mock_context()
	context.display_values["player_name"] = "Alice"
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(presenter.last_step.text, "Hello Alice.")
	context.display_values["player_name"] = "Bob"
	TranslationServer.set_locale("fr")
	assert_eq(presenter.present_call_count, 2)
	assert_eq(presenter.last_step.text, "Hello Bob.")


func _compile_fixture() -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]
