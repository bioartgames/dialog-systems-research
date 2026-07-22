class_name DialoguePresentationInput
extends Resource


## Dialogue UX input mapping (ADR-016 D22.2).
## Maps InputMap action names to presentation commands consumed by the default listener.

@export_group("Line presentation")
## InputMap action that skips typewriter reveal while [enum ConversationPhase.Phase.PresentingLine].
## Must exist in Project Settings → Input Map (built-ins allowed via [code]show_builtin[/code]).
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin,loose_mode")
var skip_typewriter_action: StringName = &"ui_accept"

@export_group("Line advance")
## InputMap action that advances after a line finishes ([enum ConversationPhase.Phase.AwaitingInput]).
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin,loose_mode")
var advance_line_action: StringName = &"ui_accept"

@export_group("Choice navigation")
## Primary InputMap action to move the choice highlight up ([enum ConversationPhase.Phase.AwaitingChoice]).
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin,loose_mode")
var navigate_choice_up_action: StringName = &"ui_up"
## Alternate InputMap action to move the choice highlight up (e.g. focus-prev).
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin,loose_mode")
var navigate_choice_up_alt_action: StringName = &"ui_focus_prev"
## Primary InputMap action to move the choice highlight down ([enum ConversationPhase.Phase.AwaitingChoice]).
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin,loose_mode")
var navigate_choice_down_action: StringName = &"ui_down"
## Alternate InputMap action to move the choice highlight down (e.g. focus-next).
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin,loose_mode")
var navigate_choice_down_alt_action: StringName = &"ui_focus_next"
## InputMap action that confirms the highlighted choice ([enum ConversationPhase.Phase.AwaitingChoice]).
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin,loose_mode")
var confirm_choice_action: StringName = &"ui_accept"
