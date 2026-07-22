class_name DialogueSpeakerSlotUiReact
extends Node

## Path to the speaker name [Label] (used for theme chrome and fallback text).
@export_node_path("Label") var speaker_label_path: NodePath
## Optional [UiStringState] for speaker text. When set, [method set_speaker_text] writes here instead of the label directly.
@export var text_state: UiStringState

var _theme: DialoguePresentationTheme
var _policy: DialoguePresentationPolicy
var _speaker_label: Label


func _ready() -> void:
	_resolve_label()


func configure(theme: DialoguePresentationTheme, policy: DialoguePresentationPolicy) -> void:
	_theme = theme
	_policy = policy
	_resolve_label()
	if _speaker_label == null:
		return
	var active_theme := DialoguePresentationResourceApplier.resolve_theme(_theme, _policy)
	_speaker_label.add_theme_color_override("font_color", active_theme.speaker_color)
	_speaker_label.add_theme_font_size_override("font_size", active_theme.speaker_font_size)


func set_speaker_text(text: String) -> void:
	if text_state != null:
		text_state.set_value(text)
	elif _speaker_label != null:
		_speaker_label.text = text
	else:
		push_warning("DialogueSpeakerSlotUiReact: no text_state or speaker label")


func clear() -> void:
	set_speaker_text("")


func _resolve_label() -> void:
	if speaker_label_path.is_empty():
		return
	_speaker_label = get_node_or_null(speaker_label_path) as Label
