extends GutTest


const CommandBridgeScript := preload(
	"res://addons/dialogue_framework/integration/command_bridge.gd"
)
const CommandBridgeRegistrarScript := preload(
	"res://addons/dialogue_framework/integration/command_bridge_registrar.gd"
)
const ResourceGameContextScript := preload(
	"res://addons/dialogue_framework/integration/resource_game_context.gd"
)


func before_each() -> void:
	CommandRegistry.clear_for_tests()


func test_registers_context_method_commands() -> void:
	var data = ResourceGameContextScript.new()
	var context: GameContext = data.make_context()
	var bridge = CommandBridgeScript.new()
	bridge.open_shop = false
	bridge.cutscene = false
	bridge.camera = false
	bridge.anim = false

	bridge.register_all(context)

	assert_true(CommandRegistry.has_command("start_quest"))
	assert_true(CommandRegistry.has_command("complete_quest"))
	assert_true(CommandRegistry.has_command("give_item"))
	assert_true(CommandRegistry.has_command("remove_item"))
	assert_false(CommandRegistry.has_command("open_shop"))
	assert_false(CommandRegistry.has_command("cutscene"))
	assert_false(CommandRegistry.has_command("camera"))
	assert_false(CommandRegistry.has_command("anim"))

	await CommandRegistry.dispatch("start_quest", PackedStringArray(["intro"]))
	assert_eq(context.get_quest_state("intro"), "active")

	await CommandRegistry.dispatch("complete_quest", PackedStringArray(["intro"]))
	assert_eq(context.get_quest_state("intro"), "complete")

	await CommandRegistry.dispatch("give_item", PackedStringArray(["scrap", "2"]))
	assert_eq(int(data.items["scrap"]), 2)

	await CommandRegistry.dispatch("remove_item", PackedStringArray(["scrap", "1"]))
	assert_eq(int(data.items["scrap"]), 1)


func test_game_mode_commands_invoke_injected_hooks_only() -> void:
	var bridge = CommandBridgeScript.new()
	bridge.start_quest = false
	bridge.complete_quest = false
	bridge.give_item = false
	bridge.remove_item = false

	var state: Dictionary = {
		"shop": "",
		"cutscene_args": PackedStringArray(),
		"camera_args": PackedStringArray(),
		"anim_args": PackedStringArray(),
	}

	bridge.register_all(
		null,
		func(shop_id: String) -> void:
			state.shop = shop_id,
		func(args: PackedStringArray) -> void:
			state.cutscene_args = args,
		func(args: PackedStringArray) -> void:
			state.camera_args = args,
		func(args: PackedStringArray) -> void:
			state.anim_args = args
	)

	await CommandRegistry.dispatch("open_shop", PackedStringArray(["blacksmith"]))
	assert_eq(state.shop, "blacksmith")

	await CommandRegistry.dispatch("cutscene", PackedStringArray(["intro_cs"]))
	assert_eq(state.cutscene_args, PackedStringArray(["intro_cs"]))

	await CommandRegistry.dispatch("camera", PackedStringArray(["pan_left"]))
	assert_eq(state.camera_args, PackedStringArray(["pan_left"]))

	await CommandRegistry.dispatch("anim", PackedStringArray(["wave", "2"]))
	assert_eq(state.anim_args, PackedStringArray(["wave", "2"]))


func test_disabled_commands_are_not_registered() -> void:
	var data = ResourceGameContextScript.new()
	var bridge = CommandBridgeScript.new()
	bridge.start_quest = true
	bridge.complete_quest = false
	bridge.give_item = false
	bridge.remove_item = false
	bridge.open_shop = false
	bridge.cutscene = false
	bridge.camera = true
	bridge.anim = false

	var camera_calls: Array = []
	bridge.register_all(
		data.make_context(),
		Callable(),
		Callable(),
		func(args: PackedStringArray) -> void:
			camera_calls.append(args),
		Callable()
	)

	assert_true(CommandRegistry.has_command("start_quest"))
	assert_false(CommandRegistry.has_command("complete_quest"))
	assert_false(CommandRegistry.has_command("give_item"))
	assert_false(CommandRegistry.has_command("remove_item"))
	assert_false(CommandRegistry.has_command("open_shop"))
	assert_false(CommandRegistry.has_command("cutscene"))
	assert_true(CommandRegistry.has_command("camera"))
	assert_false(CommandRegistry.has_command("anim"))


func test_registrar_forwards_to_bridge() -> void:
	var data = ResourceGameContextScript.new()
	var bridge = CommandBridgeScript.new()
	bridge.open_shop = false
	bridge.cutscene = false
	bridge.camera = false
	bridge.anim = false

	CommandBridgeRegistrarScript.register_all(bridge, data.make_context())
	assert_true(CommandRegistry.has_command("start_quest"))


func test_duplicate_registration_follows_registry_semantics() -> void:
	var data = ResourceGameContextScript.new()
	var bridge = CommandBridgeScript.new()
	bridge.start_quest = true
	bridge.complete_quest = false
	bridge.give_item = false
	bridge.remove_item = false
	bridge.open_shop = false
	bridge.cutscene = false
	bridge.camera = false
	bridge.anim = false

	bridge.register_all(data.make_context())
	bridge.register_all(data.make_context())

	assert_push_error("already registered")
	assert_true(CommandRegistry.has_command("start_quest"))


func test_missing_context_when_context_commands_enabled_push_error() -> void:
	var bridge = CommandBridgeScript.new()
	bridge.open_shop = false
	bridge.cutscene = false
	bridge.camera = false
	bridge.anim = false

	bridge.register_all(null)

	assert_push_error("requires a GameContext")
	assert_false(CommandRegistry.has_command("start_quest"))


func test_null_bridge_via_registrar_push_error() -> void:
	CommandBridgeRegistrarScript.register_all(null, null)
	assert_push_error("requires a CommandBridge")


func test_invalid_hook_is_noop_on_dispatch() -> void:
	var bridge = CommandBridgeScript.new()
	bridge.start_quest = false
	bridge.complete_quest = false
	bridge.give_item = false
	bridge.remove_item = false
	bridge.cutscene = false
	bridge.camera = false
	bridge.anim = false

	bridge.register_all(null, Callable())
	assert_true(CommandRegistry.has_command("open_shop"))
	await CommandRegistry.dispatch("open_shop", PackedStringArray(["x"]))
