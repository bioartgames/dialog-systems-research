class_name DialogueHudRootSlotUiReact
extends Node

@export var root_path: NodePath
@export var visible_state: UiBoolState

var _root: Control


func _ready() -> void:
	_resolve_root()


func configure(_theme: DialoguePresentationTheme, _policy: DialoguePresentationPolicy) -> void:
	_resolve_root()


func set_root_visible(show_root: bool) -> void:
	if visible_state != null:
		visible_state.set_value(show_root)
	if _root != null:
		_root.visible = show_root
	elif visible_state == null:
		push_warning("DialogueHudRootSlotUiReact: no visible_state or root")


func clear() -> void:
	set_root_visible(false)


func _resolve_root() -> void:
	if root_path.is_empty():
		return
	_root = get_node_or_null(root_path) as Control
