class_name DialogueLineSlot
extends Node

@export var line_text_path: NodePath

var _theme: DialoguePresentationTheme
var _policy: DialoguePresentationPolicy
var _line_text: RichTextLabel
var _cancel_token: int = 0


func _ready() -> void:
	_resolve_line_text()
	_configure_bbcode()


func configure(theme: DialoguePresentationTheme, policy: DialoguePresentationPolicy) -> void:
	_theme = theme
	_policy = policy
	_resolve_line_text()
	_configure_bbcode()
	if _line_text == null:
		return
	var active_theme := DialoguePresentationResourceApplier.resolve_theme(_theme, _policy)
	_line_text.add_theme_color_override("default_color", active_theme.line_color)
	_line_text.custom_minimum_size.y = active_theme.line_min_height
	DialoguePresentationResourceApplier.apply_line_overflow(_policy, _line_text)


func clear() -> void:
	cancel_reveal()
	if _line_text == null:
		return
	_line_text.text = ""
	_line_text.visible_characters = -1


func skip_to_full(full_bbcode: String) -> void:
	cancel_reveal()
	if _line_text == null:
		return
	_line_text.bbcode_text = full_bbcode
	_line_text.visible_characters = -1


func reveal_typewriter(full_bbcode: String, char_delay: float, _generation: int) -> void:
	if _line_text == null:
		return
	var token: int = _cancel_token
	_line_text.bbcode_text = full_bbcode
	if char_delay <= 0.0:
		_line_text.visible_characters = -1
		return
	_line_text.visible_characters = 0
	var char_count: int = _line_text.get_total_character_count()
	for index: int in range(1, char_count + 1):
		if token != _cancel_token:
			_line_text.visible_characters = -1
			return
		_line_text.visible_characters = index
		await get_tree().create_timer(char_delay).timeout
	_line_text.visible_characters = -1


func cancel_reveal() -> void:
	_cancel_token += 1


func get_rich_text_label() -> RichTextLabel:
	_resolve_line_text()
	return _line_text


func _resolve_line_text() -> void:
	if line_text_path.is_empty():
		return
	_line_text = get_node_or_null(line_text_path) as RichTextLabel


func _configure_bbcode() -> void:
	if _line_text != null:
		_line_text.bbcode_enabled = true
