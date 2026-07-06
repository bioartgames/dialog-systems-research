extends GutTest


func before_each() -> void:
	CommandRegistry.clear_for_tests()


func test_register_stores_handler_by_name() -> void:
	var state: Dictionary = {"called": false}
	CommandRegistry.register(
		"camera",
		func(args: PackedStringArray) -> void:
			state.called = true
	)
	assert_true(CommandRegistry.has_command("camera"))
	await CommandRegistry.dispatch("camera", PackedStringArray(["pan_left"]))
	assert_true(state.called)


func test_duplicate_registration_push_error() -> void:
	CommandRegistry.register("shop", func(_args: PackedStringArray) -> void: pass)
	CommandRegistry.register("shop", func(_args: PackedStringArray) -> void: pass)
	assert_push_error("already registered")


func test_dispatch_passes_packed_string_array_args() -> void:
	var state: Dictionary = {"received": PackedStringArray()}
	CommandRegistry.register(
		"anim",
		func(args: PackedStringArray) -> void:
			state.received = args
	)
	await CommandRegistry.dispatch("anim", PackedStringArray(["wave", "2"]))
	assert_eq(state.received, PackedStringArray(["wave", "2"]))


func test_dispatch_awaits_async_handler() -> void:
	var state: Dictionary = {"completed": false}
	var tree: SceneTree = get_tree()
	CommandRegistry.register(
		"cutscene",
		func(_args: PackedStringArray) -> void:
			await tree.create_timer(0.05).timeout
			state.completed = true
	)
	await CommandRegistry.dispatch("cutscene", PackedStringArray())
	assert_true(state.completed)


func test_dispatch_unknown_command_push_error() -> void:
	await CommandRegistry.dispatch("missing", PackedStringArray())
	assert_push_error("unknown command")
