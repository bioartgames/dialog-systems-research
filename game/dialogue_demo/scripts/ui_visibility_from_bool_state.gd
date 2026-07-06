extends Control

@export var visible_state: UiBoolState


func _ready() -> void:
	visible = false
	if visible_state == null:
		return
	visible_state.value_changed.connect(_on_visible_changed)
	_apply_visibility(bool(visible_state.get_value()))


func _on_visible_changed(new_value: Variant, _old_value: Variant) -> void:
	_apply_visibility(bool(new_value))


func _apply_visibility(show_ui: bool) -> void:
	visible = show_ui
