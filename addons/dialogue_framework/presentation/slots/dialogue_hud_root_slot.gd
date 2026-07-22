class_name DialogueHudRootSlot
extends Node

## Path to the root [Control] whose visibility gates the whole dialogue HUD.
@export_node_path("Control") var root_path: NodePath

var _root: Control


func _ready() -> void:
	_resolve_root()


func configure(_theme: DialoguePresentationTheme, _policy: DialoguePresentationPolicy) -> void:
	_resolve_root()


func set_root_visible(show_root: bool) -> void:
	if _root == null:
		push_warning("DialogueHudRootSlot: root not found")
		return
	_root.visible = show_root


func clear() -> void:
	set_root_visible(false)


func _resolve_root() -> void:
	if root_path.is_empty():
		return
	_root = get_node_or_null(root_path) as Control
