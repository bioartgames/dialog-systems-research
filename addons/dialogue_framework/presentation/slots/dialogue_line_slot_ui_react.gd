class_name DialogueLineSlotUiReact
extends Node

const _LineReveal := preload("res://addons/dialogue_framework/presentation/dialogue_line_reveal.gd")

## Path to the line body [RichTextLabel] used for BBCode / typewriter reveal.
@export_node_path("RichTextLabel") var line_text_path: NodePath
## Optional [UiStringState] mirrored for line text in Ui React layouts. When [code]null[/code], the label is driven directly.
@export var text_state: UiStringState

var _theme: DialoguePresentationTheme
var _policy: DialoguePresentationPolicy
var _line_text: RichTextLabel
var _cancel_token: int = 0


func _ready() -> void:
	_resolve_line_text()
	_LineReveal.ensure_bbcode_enabled(_line_text)


func configure(theme: DialoguePresentationTheme, policy: DialoguePresentationPolicy) -> void:
	_theme = theme
	_policy = policy
	_resolve_line_text()
	_LineReveal.ensure_bbcode_enabled(_line_text)
	if _line_text == null:
		return
	var active_theme := DialoguePresentationResourceApplier.resolve_theme(_theme, _policy)
	_line_text.add_theme_color_override("default_color", active_theme.line_color)
	_line_text.custom_minimum_size.y = active_theme.line_min_height
	DialoguePresentationResourceApplier.apply_line_overflow(_policy, _line_text)


func clear() -> void:
	cancel_reveal()
	if _line_text is UiReactRichTextLabel and text_state != null:
		text_state.set_value("\u200b")
		text_state.set_value("")
		return
	if _line_text != null:
		_LineReveal.clear(_line_text)
	if text_state != null:
		text_state.set_value("")


func skip_to_full(full_bbcode: String) -> void:
	cancel_reveal()
	if _line_text != null:
		_line_text.visible_characters = -1
	if _line_text is UiReactRichTextLabel:
		if text_state != null:
			text_state.set_value(full_bbcode)
		return
	_LineReveal.skip_to_full(_line_text, full_bbcode)
	if text_state != null:
		text_state.set_value(full_bbcode)


func reveal_typewriter(full_bbcode: String, char_delay: float, _generation: int) -> void:
	if _line_text == null:
		push_warning("DialogueLineSlotUiReact: line text not found")
		return
	var token: int = _cancel_token
	var slot_ref: WeakRef = weakref(self)
	if char_delay <= 0.0:
		skip_to_full(full_bbcode)
		return
	await _LineReveal.reveal_typewriter(
		_line_text,
		full_bbcode,
		char_delay,
		func() -> bool:
			var slot_obj: DialogueLineSlotUiReact = slot_ref.get_ref() as DialogueLineSlotUiReact
			if slot_obj == null:
				return true
			return token != slot_obj._cancel_token,
		get_tree()
	)
	if text_state != null:
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
