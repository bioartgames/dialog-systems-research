class_name DialoguePanelSlot
extends Node

enum PanelMotionProfile {
	INSTANT,
	CHOICES_INTRO_OUTRO,
	LINE_OUTRO,
}

## Path to the [PanelContainer] this slot controls.
@export_node_path("PanelContainer") var panel_path: NodePath
## When [code]true[/code], apply line-panel theme chrome; when [code]false[/code], apply choices-panel chrome tokens.
@export var apply_line_panel_chrome: bool = true
## Which policy durations drive intro/outro for this panel instance.
## [enum PanelMotionProfile.INSTANT]: no intro/outro duration.
## [enum PanelMotionProfile.CHOICES_INTRO_OUTRO]: [member DialoguePresentationPolicy.choices_intro_duration_sec] / [member DialoguePresentationPolicy.choices_dismiss_duration_sec].
## [enum PanelMotionProfile.LINE_OUTRO]: [member DialoguePresentationPolicy.line_dismiss_duration_sec] on outro only.
@export var motion_profile: PanelMotionProfile = PanelMotionProfile.INSTANT

var _theme: DialoguePresentationTheme
var _policy: DialoguePresentationPolicy
var _panel: PanelContainer
var _dismiss_token: int = 0


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


func is_panel_visible() -> bool:
	_resolve_panel()
	return _panel != null and _panel.visible


func set_panel_visible(show_panel: bool) -> void:
	_resolve_panel()
	if _panel == null:
		push_warning("DialoguePanelSlot: panel not found")
		return
	if show_panel:
		_invalidate_in_flight_dismiss()
		_panel.visible = true
		_start_intro_if_configured()
	else:
		_panel.visible = false


func clear() -> void:
	set_panel_visible(false)


func dismiss_panel() -> void:
	_resolve_panel()
	if _panel == null:
		return
	var duration: float = _outro_duration()
	if duration <= 0.0:
		set_panel_visible(false)
		return
	var token: int = _dismiss_token
	await get_tree().create_timer(duration).timeout
	if _is_dismiss_token_current(token):
		set_panel_visible(false)


func _intro_duration() -> float:
	match motion_profile:
		PanelMotionProfile.CHOICES_INTRO_OUTRO:
			return DialoguePresentationResourceApplier.choices_intro_duration(_policy)
		_:
			return 0.0


func _outro_duration() -> float:
	match motion_profile:
		PanelMotionProfile.CHOICES_INTRO_OUTRO:
			return DialoguePresentationResourceApplier.choices_dismiss_duration(_policy)
		PanelMotionProfile.LINE_OUTRO:
			return DialoguePresentationResourceApplier.line_dismiss_duration(_policy)
		_:
			return 0.0


func _start_intro_if_configured() -> void:
	if _intro_duration() <= 0.0:
		return


func _invalidate_in_flight_dismiss() -> void:
	_dismiss_token += 1


func _is_dismiss_token_current(token: int) -> bool:
	return token == _dismiss_token


func _resolve_panel() -> void:
	if panel_path.is_empty():
		return
	_panel = get_node_or_null(panel_path) as PanelContainer
