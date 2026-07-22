class_name CommandBridgeRegistrar
extends RefCounted

## Static entry point for CommandBridge registration (ADR-024 / IK-2).
## Forwards to CommandBridge.register_all — uses CommandRegistry.register only.


static func register_all(
	bridge: Resource,
	context: GameContext = null,
	on_open_shop: Callable = Callable(),
	on_cutscene: Callable = Callable(),
	on_camera: Callable = Callable(),
	on_anim: Callable = Callable()
) -> void:
	if bridge == null or not bridge.has_method("register_all"):
		push_error("CommandBridgeRegistrar.register_all() requires a CommandBridge.")
		return
	bridge.register_all(context, on_open_shop, on_cutscene, on_camera, on_anim)
