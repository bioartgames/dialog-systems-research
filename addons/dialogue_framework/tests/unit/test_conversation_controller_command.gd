extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"


func before_each() -> void:
	CommandRegistry.clear_for_tests()


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


func test_command_at_start_sets_executing_command_and_auto_advances() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\n@set_flag met_roll true\nRoll: After command.\n",
		"res://test/command_at_start.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	await get_tree().create_timer(0.1).timeout
	assert_eq(context.get_flag("met_roll"), true)
	assert_eq(presenter.last_step.text, "After command.")
	assert_eq(controller._phase, ConversationPhase.Phase.PresentingLine)


func test_advance_to_command_sets_executing_command_and_auto_advances() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\nRoll: Before command.\n@set_flag met_roll true\nRoll: After command.\n",
		"res://test/command_after_line.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	await get_tree().create_timer(0.1).timeout
	assert_eq(context.get_flag("met_roll"), true)
	assert_eq(presenter.last_step.text, "After command.")


func test_command_dismisses_presenter_when_advancing_from_line() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\nRoll: Before command.\n@set_flag met_roll true\nRoll: After command.\n",
		"res://test/command_dismiss.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	assert_true(controller.start(compiled, "start", context, presenter))
	controller.notify_presentation_finished()
	controller.advance()
	await get_tree().create_timer(0.1).timeout
	assert_eq(presenter.dismiss_call_count, 1)


func test_set_flag_emits_command_executed_and_emit_uses_builtin_payload() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\n@set_flag met_roll true\n@emit door_opened\nRoll: Done.\n",
		"res://test/command_signals.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var emissions: Array = []
	controller.command_executed.connect(
		func(command_name: String, args: Array) -> void:
			emissions.append({"command_name": command_name, "args": args})
	)
	assert_true(controller.start(compiled, "start", context, presenter))
	await get_tree().create_timer(0.1).timeout
	assert_eq(emissions.size(), 2)
	assert_eq(emissions[0]["command_name"], "set_flag")
	assert_eq(emissions[0]["args"], ["met_roll", true])
	assert_eq(emissions[1]["command_name"], "emit")
	assert_eq(emissions[1]["args"], ["door_opened"])
	assert_eq(presenter.last_step.text, "Done.")


func test_async_registry_handler_is_awaited_before_auto_advance() -> void:
	var manifest_path: String = "res://addons/dialogue_framework/tests/fixtures/test_command_manifest.tres"
	var setting_key: String = "dialogue_framework/command_manifest_path"
	var previous_path: Variant = ProjectSettings.get_setting(setting_key)
	ProjectSettings.set_setting(setting_key, manifest_path)
	var compiled: CompiledDialogue = _compile(
		"~ start\n@cutscene intro\nRoll: After cutscene.\n",
		"res://test/async_command.dlg"
	)
	if previous_path == null:
		ProjectSettings.set_setting(setting_key, "")
	else:
		ProjectSettings.set_setting(setting_key, previous_path)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var tree: SceneTree = get_tree()
	var state: Dictionary = {"completed": false}
	CommandRegistry.register(
		"cutscene",
		func(_args: PackedStringArray) -> void:
			await tree.create_timer(0.05).timeout
			state.completed = true
	)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_false(state.completed)
	await get_tree().create_timer(0.1).timeout
	assert_true(state.completed)
	assert_eq(presenter.last_step.text, "After cutscene.")
