class_name DialoguePanelSlotUiReact
extends DialoguePanelSlot

@export var visible_state: UiBoolState
@export var open_animation: UiAnimTarget
@export var dismiss_animation: UiAnimTarget


func set_panel_visible(show_panel: bool) -> void:
	_resolve_panel()
	if show_panel:
		if visible_state != null:
			visible_state.set_value(true)
		if _panel != null:
			_panel.visible = true
		_start_intro_if_configured()
	elif visible_state != null:
		visible_state.set_value(false)
		if _panel != null:
			_panel.visible = false
	elif _panel != null:
		_panel.visible = false
	else:
		push_warning("DialoguePanelSlotUiReact: no visible_state or panel")


func _start_intro_if_configured() -> void:
	var duration: float = _intro_duration()
	if duration <= 0.0:
		return
	if open_animation != null:
		open_animation.duration = duration
		open_animation.apply(self)


func dismiss_panel() -> void:
	_resolve_panel()
	if _panel == null:
		return
	var duration: float = _outro_duration()
	if duration <= 0.0:
		set_panel_visible(false)
		return
	if dismiss_animation != null:
		dismiss_animation.duration = duration
	if visible_state != null:
		visible_state.set_value(false)
	if dismiss_animation != null:
		dismiss_animation.apply(self)
	await get_tree().create_timer(duration).timeout
	if _panel != null:
		_panel.visible = false
