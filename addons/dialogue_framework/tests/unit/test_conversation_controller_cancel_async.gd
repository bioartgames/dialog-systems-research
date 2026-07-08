extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const MANIFEST_PATH := "res://addons/dialogue_framework/tests/fixtures/test_command_manifest.tres"
const COMMAND_SETTING := "dialogue_framework/command_manifest_path"


func before_each() -> void:
	CommandRegistry.clear_for_tests()
	DialogueFrameworkProjectSettings.register_settings()


func _compile_cutscene_dialogue() -> CompiledDialogue:
	var previous: Variant = ProjectSettings.get_setting(COMMAND_SETTING)
	ProjectSettings.set_setting(COMMAND_SETTING, MANIFEST_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(
		"~ start\n@cutscene intro\nRoll: After cutscene.\n",
		"res://test/cancel_async.dlg"
	)
	ProjectSettings.set_setting(COMMAND_SETTING, previous)
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


func test_cancel_abandons_in_flight_async_command_flow() -> void:
	var compiled: CompiledDialogue = _compile_cutscene_dialogue()
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var tree: SceneTree = get_tree()
	var handler_state: Dictionary = {"completed": false}
	var delivered_texts: PackedStringArray = PackedStringArray()
	CommandRegistry.register(
		"cutscene",
		func(_args: PackedStringArray) -> void:
			await tree.create_timer(0.2).timeout
			handler_state.completed = true
	)
	controller.step_ready.connect(
		func(step: ConversationStep) -> void:
			if not step.text.is_empty():
				delivered_texts.append(step.text)
	)
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_false(handler_state.completed)
	controller.cancel()
	await tree.create_timer(0.3).timeout
	assert_eq(controller._phase, ConversationPhase.Phase.Idle)
	assert_signal_emitted(controller, "conversation_cancelled")
	assert_false(delivered_texts.has("After cutscene."))
