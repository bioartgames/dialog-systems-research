class_name DialogueChoicesSlot
extends Node

@export var choices_stack_path: NodePath

var _theme: DialoguePresentationTheme
var _policy: DialoguePresentationPolicy
var _choices_stack: VBoxContainer


func _ready() -> void:
	_resolve_stack()


func configure(theme: DialoguePresentationTheme, policy: DialoguePresentationPolicy) -> void:
	_theme = theme
	_policy = policy
	_resolve_stack()
	if _choices_stack == null:
		return
	var active_theme := DialoguePresentationResourceApplier.resolve_theme(_theme, _policy)
	_choices_stack.add_theme_constant_override("separation", active_theme.choice_separation)


func get_choice_container() -> Container:
	_resolve_stack()
	return _choices_stack


func _resolve_stack() -> void:
	if choices_stack_path.is_empty():
		return
	_choices_stack = get_node_or_null(choices_stack_path) as VBoxContainer
