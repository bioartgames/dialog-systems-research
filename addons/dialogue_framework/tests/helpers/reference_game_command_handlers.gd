extends RefCounted

## Reference registration patterns for game `@commands` (D10.2–D10.6).
## Lives under tests/helpers only — the framework does not ship shop, cutscene, or camera logic.


static func register_open_shop_handler(on_open_shop: Callable) -> void:
	CommandRegistry.register(
		"open_shop",
		func(args: PackedStringArray) -> void:
			var shop_id: String = args[0] if args.size() > 0 else ""
			if on_open_shop != null and on_open_shop.is_valid():
				on_open_shop.call(shop_id)
	)


static func register_cutscene_handler(play_cutscene: Callable) -> void:
	CommandRegistry.register(
		"cutscene",
		func(args: PackedStringArray) -> void:
			if play_cutscene != null and play_cutscene.is_valid():
				await play_cutscene.call(args)
	)


static func register_quest_handlers(context: GameContext) -> void:
	CommandRegistry.register(
		"start_quest",
		func(args: PackedStringArray) -> void:
			if args.is_empty():
				return
			context.start_quest(args[0])
	)
	CommandRegistry.register(
		"complete_quest",
		func(args: PackedStringArray) -> void:
			if args.is_empty():
				return
			context.complete_quest(args[0])
	)


static func register_inventory_handlers(context: GameContext) -> void:
	CommandRegistry.register(
		"give_item",
		func(args: PackedStringArray) -> void:
			if args.is_empty():
				return
			var count: int = int(args[1]) if args.size() > 1 else 1
			context.give_item(args[0], count)
	)
	CommandRegistry.register(
		"remove_item",
		func(args: PackedStringArray) -> void:
			if args.is_empty():
				return
			var count: int = int(args[1]) if args.size() > 1 else 1
			context.remove_item(args[0], count)
	)


static func register_camera_handler(on_camera: Callable) -> void:
	CommandRegistry.register(
		"camera",
		func(args: PackedStringArray) -> void:
			if on_camera != null and on_camera.is_valid():
				on_camera.call(args)
	)


static func register_anim_handler(on_anim: Callable) -> void:
	CommandRegistry.register(
		"anim",
		func(args: PackedStringArray) -> void:
			if on_anim != null and on_anim.is_valid():
				on_anim.call(args)
	)
