class_name CommandBridge
extends Resource

## Inspector config for optional @command registration (ADR-024 / IK-2).
## Selects which command names to wire to GameContext methods and/or
## game-supplied Callables. Does not implement shop/cutscene/camera/anim
## bodies — hooks only (ADR-009 D10.2–D10.3, ADR-024 D30.5).
##
## Duplicate names follow existing CommandRegistry semantics (push_error,
## keep the first handler). Prefer CommandBridgeRegistrar.register_all for
## the static call site used by starters / showcase migration.


@export_group("Context commands")
@export var start_quest: bool = true
@export var complete_quest: bool = true
@export var give_item: bool = true
@export var remove_item: bool = true

@export_group("Game-mode hooks")
@export var open_shop: bool = true
@export var cutscene: bool = true
@export var camera: bool = true
@export var anim: bool = true


## Registers enabled commands via CommandRegistry.register only.
func register_all(
	context: GameContext = null,
	on_open_shop: Callable = Callable(),
	on_cutscene: Callable = Callable(),
	on_camera: Callable = Callable(),
	on_anim: Callable = Callable()
) -> void:
	_register_context_commands(context)
	_register_hook_commands(on_open_shop, on_cutscene, on_camera, on_anim)


func _register_context_commands(context: GameContext) -> void:
	var needs_context: bool = (
		start_quest
		or complete_quest
		or give_item
		or remove_item
	)
	if needs_context and context == null:
		push_error(
			"CommandBridge.register_all() requires a GameContext when context commands are enabled."
		)
		return

	if start_quest:
		CommandRegistry.register(
			"start_quest",
			func(args: PackedStringArray) -> void:
				if not args.is_empty():
					context.start_quest(args[0])
		)
	if complete_quest:
		CommandRegistry.register(
			"complete_quest",
			func(args: PackedStringArray) -> void:
				if not args.is_empty():
					context.complete_quest(args[0])
		)
	if give_item:
		CommandRegistry.register(
			"give_item",
			func(args: PackedStringArray) -> void:
				if args.is_empty():
					return
				var count: int = int(args[1]) if args.size() > 1 else 1
				context.give_item(args[0], count)
		)
	if remove_item:
		CommandRegistry.register(
			"remove_item",
			func(args: PackedStringArray) -> void:
				if args.is_empty():
					return
				var count: int = int(args[1]) if args.size() > 1 else 1
				context.remove_item(args[0], count)
		)


func _register_hook_commands(
	on_open_shop: Callable,
	on_cutscene: Callable,
	on_camera: Callable,
	on_anim: Callable
) -> void:
	if open_shop:
		CommandRegistry.register(
			"open_shop",
			func(args: PackedStringArray) -> void:
				var shop_id: String = args[0] if args.size() > 0 else ""
				if on_open_shop.is_valid():
					on_open_shop.call(shop_id)
		)
	if cutscene:
		CommandRegistry.register(
			"cutscene",
			func(args: PackedStringArray) -> void:
				if on_cutscene.is_valid():
					await on_cutscene.call(args)
		)
	if camera:
		CommandRegistry.register(
			"camera",
			func(args: PackedStringArray) -> void:
				if on_camera.is_valid():
					on_camera.call(args)
		)
	if anim:
		CommandRegistry.register(
			"anim",
			func(args: PackedStringArray) -> void:
				if on_anim.is_valid():
					on_anim.call(args)
		)
