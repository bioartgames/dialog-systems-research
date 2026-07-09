class_name DialoguePresentationInput
extends Resource


## Dialogue UX input mapping (ADR-016 D22.2).
## Maps InputMap action names to presentation commands consumed by the default listener.

@export_group("Line presentation")
@export var skip_typewriter_action: StringName = &"ui_accept"

@export_group("Line advance")
@export var advance_line_action: StringName = &"ui_accept"

@export_group("Choice navigation")
@export var navigate_choice_up_action: StringName = &"ui_up"
@export var navigate_choice_up_alt_action: StringName = &"ui_focus_prev"
@export var navigate_choice_down_action: StringName = &"ui_down"
@export var navigate_choice_down_alt_action: StringName = &"ui_focus_next"
@export var confirm_choice_action: StringName = &"ui_accept"
