class_name ConversationStarter
extends Node

## Inspector-configured conversation start/cancel (ADR-024 / IK-4).
## Wires existing ConversationController APIs only. Does not import Presentation —
## resolve the presenter via NodePath to an IDialoguePresenter in the scene tree.
## Does not own demo UI, locale toggles, or snapshot I/O.


@export_group("Dialogue")
@export var compiled_dialogue: CompiledDialogue
@export_file("*.dlg", "*.tres", "*.res") var dialogue_path: String = ""
@export var entry_title: String = "start"

@export_group("Wiring")
@export var presenter_path: NodePath
@export var context_resource: ResourceGameContext
@export var command_bridge: CommandBridge
@export var register_commands_on_ready: bool = true

## Optional game-mode hooks for CommandBridge (set from code).
var on_open_shop: Callable = Callable()
var on_cutscene: Callable = Callable()
var on_camera: Callable = Callable()
var on_anim: Callable = Callable()

var _injected_context: GameContext = null
var _bound_context: GameContext = null
var _controller_override: Node = null
var _commands_registered: bool = false


func _ready() -> void:
	if register_commands_on_ready:
		_ensure_commands_registered()


## Inject a custom GameContext (takes precedence over context_resource).
func set_context(context: GameContext) -> void:
	_injected_context = context
	_bound_context = null
	_commands_registered = false


## Test / advanced: use a specific controller Node instead of the autoload.
func set_controller(controller: Node) -> void:
	_controller_override = controller


func start_conversation() -> bool:
	_ensure_commands_registered()
	var compiled: CompiledDialogue = _resolve_compiled()
	if compiled == null:
		push_error("ConversationStarter.start_conversation() could not resolve CompiledDialogue.")
		return false
	var context: GameContext = _resolve_context()
	if context == null:
		push_error("ConversationStarter.start_conversation() requires a GameContext.")
		return false
	var presenter: IDialoguePresenter = _resolve_presenter()
	if presenter == null:
		push_error(
			"ConversationStarter.start_conversation() requires presenter_path to an IDialoguePresenter."
		)
		return false
	var controller: Node = _get_controller()
	if controller == null or not controller.has_method("start"):
		push_error("ConversationStarter.start_conversation() could not resolve ConversationController.")
		return false
	return bool(controller.start(compiled, entry_title, context, presenter))


func cancel_conversation() -> void:
	var controller: Node = _get_controller()
	if controller == null or not controller.has_method("cancel"):
		push_error("ConversationStarter.cancel_conversation() could not resolve ConversationController.")
		return
	controller.cancel()


func _get_controller() -> Node:
	if _controller_override != null:
		return _controller_override
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("ConversationController")


func _resolve_compiled() -> CompiledDialogue:
	if compiled_dialogue != null:
		return compiled_dialogue
	var trimmed: String = dialogue_path.strip_edges()
	if trimmed.is_empty():
		return null
	var result: Dictionary = CompiledDialogueLoader.load_compiled(trimmed)
	return result.get("compiled") as CompiledDialogue


func _resolve_context() -> GameContext:
	if _bound_context != null:
		return _bound_context
	if _injected_context != null:
		_bound_context = _injected_context
	elif context_resource != null:
		_bound_context = context_resource.make_context()
	return _bound_context


func _resolve_presenter() -> IDialoguePresenter:
	if presenter_path.is_empty():
		return null
	var node: Node = get_node_or_null(presenter_path)
	if node is IDialoguePresenter:
		return node as IDialoguePresenter
	return null


func _ensure_commands_registered() -> void:
	if _commands_registered or command_bridge == null:
		return
	var context: GameContext = _resolve_context()
	CommandBridgeRegistrar.register_all(
		command_bridge,
		context,
		on_open_shop,
		on_cutscene,
		on_camera,
		on_anim
	)
	_commands_registered = true
