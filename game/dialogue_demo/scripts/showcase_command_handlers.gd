class_name ShowcaseCommandHandlers
extends RefCounted

## Demo-local dual-path wrapper over Integration kit CommandBridge (ADR-024 IK-7).
## New game code should use ConversationStarter + CommandBridge instead.


const _CommandBridge := preload(
	"res://addons/dialogue_framework/integration/command_bridge.gd"
)
const _CommandBridgeRegistrar := preload(
	"res://addons/dialogue_framework/integration/command_bridge_registrar.gd"
)


static func register_all(
	context: ShowcaseGameContext,
	on_open_shop: Callable,
	on_cutscene: Callable,
	on_camera: Callable,
	on_anim: Callable
) -> void:
	var bridge = _CommandBridge.new()
	_CommandBridgeRegistrar.register_all(
		bridge,
		context,
		on_open_shop,
		on_cutscene,
		on_camera,
		on_anim
	)
