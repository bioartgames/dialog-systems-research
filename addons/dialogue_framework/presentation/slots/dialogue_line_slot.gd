class_name DialogueLineSlot
extends Node

const _LineReveal := preload("res://addons/dialogue_framework/presentation/dialogue_line_reveal.gd")

## Path to the line body [RichTextLabel] used for BBCode / typewriter reveal.
@export_node_path("RichTextLabel") var line_text_path: NodePath

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
	_LineReveal.clear(_line_text)


func skip_to_full(full_bbcode: String) -> void:
	cancel_reveal()
	_LineReveal.skip_to_full(_line_text, full_bbcode)


func reveal_typewriter(full_bbcode: String, char_delay: float, _generation: int) -> void:
	if _line_text == null:
		return
	var token: int = _cancel_token
	var slot_ref: WeakRef = weakref(self)
	await _LineReveal.reveal_typewriter(
		_line_text,
		full_bbcode,
		char_delay,
		func() -> bool:
			var slot_obj: DialogueLineSlot = slot_ref.get_ref() as DialogueLineSlot
			if slot_obj == null:
				return true
			return token != slot_obj._cancel_token,
		get_tree()
	)


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
	_LineReveal.ensure_bbcode_enabled(_line_text)
