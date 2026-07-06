class_name ShowcaseCommandHandlers
extends RefCounted


static func register_all(
	context: ShowcaseGameContext,
	on_open_shop: Callable,
	on_cutscene: Callable,
	on_camera: Callable,
	on_anim: Callable
) -> void:
	CommandRegistry.register(
		"open_shop",
		func(args: PackedStringArray) -> void:
			var shop_id: String = args[0] if args.size() > 0 else ""
			if on_open_shop.is_valid():
				on_open_shop.call(shop_id)
	)
	CommandRegistry.register(
		"cutscene",
		func(args: PackedStringArray) -> void:
			if on_cutscene.is_valid():
				await on_cutscene.call(args)
	)
	CommandRegistry.register(
		"start_quest",
		func(args: PackedStringArray) -> void:
			if not args.is_empty():
				context.start_quest(args[0])
	)
	CommandRegistry.register(
		"complete_quest",
		func(args: PackedStringArray) -> void:
			if not args.is_empty():
				context.complete_quest(args[0])
	)
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
	CommandRegistry.register(
		"camera",
		func(args: PackedStringArray) -> void:
			if on_camera.is_valid():
				on_camera.call(args)
	)
	CommandRegistry.register(
		"anim",
		func(args: PackedStringArray) -> void:
			if on_anim.is_valid():
				on_anim.call(args)
	)
