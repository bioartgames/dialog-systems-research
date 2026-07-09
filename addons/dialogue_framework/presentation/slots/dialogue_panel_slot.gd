class_name DialoguePanelSlot
extends Node

@export var panel_path: NodePath
@export var apply_line_panel_chrome: bool = true

var _theme: DialoguePresentationTheme
var _policy: DialoguePresentationPolicy
var _panel: PanelContainer


func _ready() -> void:
	_resolve_panel()


func configure(theme: DialoguePresentationTheme, policy: DialoguePresentationPolicy) -> void:
	_theme = theme
	_policy = policy
	_resolve_panel()
	if _panel == null:
		return
	var active_theme := DialoguePresentationResourceApplier.resolve_theme(_theme, _policy)
	DialoguePresentationResourceApplier.apply_panel_container_chrome(
		_panel, active_theme, apply_line_panel_chrome
	)


func set_panel_visible(show_panel: bool) -> void:
	if _panel == null:
		push_warning("DialoguePanelSlot: panel not found")
		return
	_panel.visible = show_panel


func clear() -> void:
	set_panel_visible(false)


func _resolve_panel() -> void:
	if panel_path.is_empty():
		return
	_panel = get_node_or_null(panel_path) as PanelContainer
