extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const MANIFEST_PATH := (
	"res://addons/dialogue_framework/tests/fixtures/reference_game_command_manifest.tres"
)
const MANIFEST_SETTING := "dialogue_framework/command_manifest_path"
const ReferenceGameCommandHandlers = preload(
	"res://addons/dialogue_framework/tests/helpers/reference_game_command_handlers.gd"
)


func before_each() -> void:
	CommandRegistry.clear_for_tests()


func _with_manifest_path(manifest_path: String) -> Variant:
	var previous: Variant = ProjectSettings.get_setting(MANIFEST_SETTING)
	ProjectSettings.set_setting(MANIFEST_SETTING, manifest_path)
	return previous


func _restore_manifest_path(previous: Variant) -> void:
	if previous == null:
		ProjectSettings.set_setting(MANIFEST_SETTING, "")
	else:
		ProjectSettings.set_setting(MANIFEST_SETTING, previous)


func _compile(source_text: String, path: String) -> CompiledDialogue:
	var previous: Variant = _with_manifest_path(MANIFEST_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	_restore_manifest_path(previous)
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


func test_game_commands_require_command_manifest_at_compile_time() -> void:
	var previous: Variant = _with_manifest_path("")
	var result: Dictionary = DialogueCompiler.compile_string(
		"~ start\n@open_shop store_a\n=> END\n",
		"res://test/reference_manifest_required.dlg"
	)
	_restore_manifest_path(previous)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])


func test_open_shop_reference_pattern_cancels_conversation() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\n@open_shop general_store\n=> END\n",
		"res://test/reference_open_shop.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var state: Dictionary = {"shop_id": "", "cancelled": false}
	ReferenceGameCommandHandlers.register_open_shop_handler(
		func(shop_id: String) -> void:
			state.shop_id = shop_id
			controller.cancel()
			state.cancelled = true
	)
	assert_true(controller.start(compiled, "start", context, presenter))
	await get_tree().create_timer(0.1).timeout
	assert_eq(state.shop_id, "general_store")
	assert_true(state.cancelled)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)


func test_cutscene_reference_pattern_is_async_before_next_line() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\n@cutscene intro\nRoll: After cutscene.\n",
		"res://test/reference_cutscene.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var tree: SceneTree = get_tree()
	var state: Dictionary = {"played": false, "args": PackedStringArray()}
	ReferenceGameCommandHandlers.register_cutscene_handler(
		func(args: PackedStringArray) -> void:
			state.args = args
			await tree.create_timer(0.05).timeout
			state.played = true
	)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_false(state.played)
	await get_tree().create_timer(0.1).timeout
	assert_true(state.played)
	assert_eq(state.args, PackedStringArray(["intro"]))
	assert_eq(presenter.last_step.text, "After cutscene.")


func test_quest_command_reference_pattern_updates_game_context() -> void:
	var compiled: CompiledDialogue = _compile(
		(
			"~ start\n"
			+ "@start_quest find_key\n"
			+ "@complete_quest find_key\n"
			+ "Roll: Quest updated.\n"
		),
		"res://test/reference_quest.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	ReferenceGameCommandHandlers.register_quest_handlers(context)
	assert_true(controller.start(compiled, "start", context, presenter))
	await get_tree().create_timer(0.1).timeout
	assert_eq(context.get_quest_state("find_key"), "complete")
	assert_eq(presenter.last_step.text, "Quest updated.")


func test_inventory_reference_pattern_give_item_and_has_item_condition() -> void:
	var compiled: CompiledDialogue = _compile(
		(
			"~ start\n"
			+ 'if has_item("brass_key"):\n'
			+ "    Roll: Already have the key.\n"
			+ "else:\n"
			+ "    @give_item brass_key 1\n"
			+ "    Roll: Here is a spare key.\n"
		),
		"res://test/reference_inventory.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	ReferenceGameCommandHandlers.register_inventory_handlers(context)
	assert_true(controller.start(compiled, "start", context, presenter))
	await get_tree().create_timer(0.1).timeout
	assert_true(context.has_item("brass_key"))
	assert_eq(presenter.last_step.text, "Here is a spare key.")


func test_camera_and_anim_reference_patterns_dispatch_to_game_handlers() -> void:
	var compiled: CompiledDialogue = _compile(
		"~ start\n@camera pan_to roll 1.5\n@anim wave 2\nRoll: Done.\n",
		"res://test/reference_camera_anim.dlg"
	)
	var context: GameContext = _mock_context()
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	var state: Dictionary = {"camera": PackedStringArray(), "anim": PackedStringArray()}
	ReferenceGameCommandHandlers.register_camera_handler(
		func(args: PackedStringArray) -> void:
			state.camera = args
	)
	ReferenceGameCommandHandlers.register_anim_handler(
		func(args: PackedStringArray) -> void:
			state.anim = args
	)
	assert_true(controller.start(compiled, "start", context, presenter))
	await get_tree().create_timer(0.1).timeout
	assert_eq(state.camera, PackedStringArray(["pan_to", "roll", "1.5"]))
	assert_eq(state.anim, PackedStringArray(["wave", "2"]))
	assert_eq(presenter.last_step.text, "Done.")
