class_name DialoguePanelSlot
extends Node

@export var panel_path: NodePath

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
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = active_theme.panel_bg_color
	panel_style.set_corner_radius_all(active_theme.panel_corner_radius)
	panel_style.content_margin_left = active_theme.panel_content_margin.x
	panel_style.content_margin_top = active_theme.panel_content_margin.y
	panel_style.content_margin_right = active_theme.panel_content_margin.z
	panel_style.content_margin_bottom = active_theme.panel_content_margin.w
	_panel.add_theme_stylebox_override("panel", panel_style)


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
