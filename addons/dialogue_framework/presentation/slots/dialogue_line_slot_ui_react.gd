class_name DialogueLineSlotUiReact
extends Node

@export var line_text_path: NodePath
@export var text_state: UiStringState

var _theme: DialoguePresentationTheme
var _policy: DialoguePresentationPolicy
var _line_text: RichTextLabel
var _cancel_token: int = 0


func _ready() -> void:
	_resolve_line_text()


func configure(theme: DialoguePresentationTheme, policy: DialoguePresentationPolicy) -> void:
	_theme = theme
	_policy = policy
	_resolve_line_text()
	if _line_text != null:
		var active_theme := DialoguePresentationResourceApplier.resolve_theme(_theme, _policy)
		_line_text.add_theme_color_override("default_color", active_theme.line_color)
		_line_text.custom_minimum_size.y = active_theme.line_min_height
		DialoguePresentationResourceApplier.apply_line_overflow(_policy, _line_text)


func clear() -> void:
	cancel_reveal()
	if text_state != null:
		text_state.set_value("")


func skip_to_full(full_bbcode: String) -> void:
	cancel_reveal()
	if text_state != null:
		text_state.set_value(full_bbcode)


func reveal_typewriter(full_bbcode: String, char_delay: float, _generation: int) -> void:
	if text_state == null:
		return
	var token: int = _cancel_token
	if char_delay <= 0.0:
		text_state.set_value(full_bbcode)
		return
	var revealed: String = ""
	for index: int in full_bbcode.length():
		if token != _cancel_token:
			text_state.set_value(full_bbcode)
			return
		revealed = full_bbcode.substr(0, index + 1)
		text_state.set_value(revealed)
		await get_tree().create_timer(char_delay).timeout
	text_state.set_value(full_bbcode)


func cancel_reveal() -> void:
	_cancel_token += 1


func get_rich_text_label() -> RichTextLabel:
	_resolve_line_text()
	return _line_text


func _resolve_line_text() -> void:
	if line_text_path.is_empty():
		return
	_line_text = get_node_or_null(line_text_path) as RichTextLabel
