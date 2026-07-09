class_name NativeDialoguePresenter
extends IDialoguePresenter

const TYPEWRITER_CHAR_DELAY: float = 0.03
const TIME_AUTO_CHARS_PER_SEC: float = 0.02
const TIME_AUTO_MIN: float = 0.5
const TIME_AUTO_MAX: float = 8.0

const _CHOICE_BG := Color(0.08, 0.09, 0.12, 0.9)
const _CHOICE_HOVER_BG := Color(0.12, 0.13, 0.18, 0.95)
const _CHOICE_SELECTED_BG := Color(0.14, 0.16, 0.22, 0.98)
const _CHOICE_BORDER := Color(0.92, 0.94, 1.0, 0.85)

@export var speaker_label_path: NodePath
@export var line_text_path: NodePath
@export var choices_stack_path: NodePath
@export var line_panel_path: NodePath
@export var choices_panel_path: NodePath
@export var theme: DialoguePresentationTheme
@export var policy: DialoguePresentationPolicy
@export var input: DialoguePresentationInput
@export var typewriter_char_delay: float = TYPEWRITER_CHAR_DELAY

var _speaker_label: Label
var _line_text: RichTextLabel
var _choices_stack: VBoxContainer
var _line_panel: CanvasItem
var _choices_panel: CanvasItem
var _voice_player: AudioStreamPlayer
var _choice_buttons: Array[Button] = []
var _option_indices: Array[int] = []
var _presentation_gen: int = 0
var _bbcode_strip_regex: RegEx
var _active_full_text: String = ""
var _skip_typewriter: bool = false
var _choices_input_enabled: bool = false
var _selected_row: int = 0

var _choice_style_normal: StyleBoxFlat
var _choice_style_hover: StyleBoxFlat
var _choice_style_selected: StyleBoxFlat


func _ready() -> void:
	_bbcode_strip_regex = RegEx.new()
	_bbcode_strip_regex.compile("\\[/?[^\\]]+\\]")
	_voice_player = AudioStreamPlayer.new()
	add_child(_voice_player)
	_resolve_node_refs()
	_configure_line_text()
	_build_choice_styles()
	_hide_panels()


func present(step: ConversationStep) -> void:
	match step.kind:
		ConversationStepKind.Kind.LINE:
			_cancel_full_presentation()
			_present_line(step)
		ConversationStepKind.Kind.CHOICES:
			_clear_choices_presentation()
			_present_choices(step)


func dismiss() -> void:
	_cancel_full_presentation()
	_hide_panels()


func request_skip_typewriter() -> void:
	if _active_full_text.is_empty():
		return
	_skip_typewriter = true
	if _line_text != null:
		_line_text.bbcode_text = _active_full_text
		_line_text.visible_characters = -1


func navigate_choice(delta: int) -> void:
	if _choice_buttons.is_empty():
		return
	var row_count: int = _choice_buttons.size()
	_set_selected_row(wrapi(_selected_row + delta, 0, row_count))


func confirm_selected_choice() -> void:
	_on_choice_button_pressed(_selected_row)


func _resolve_node_refs() -> void:
	if not speaker_label_path.is_empty():
		_speaker_label = get_node(speaker_label_path) as Label
	if not line_text_path.is_empty():
		_line_text = get_node(line_text_path) as RichTextLabel
	if not choices_stack_path.is_empty():
		_choices_stack = get_node(choices_stack_path) as VBoxContainer
	if not line_panel_path.is_empty():
		_line_panel = get_node(line_panel_path) as CanvasItem
	if not choices_panel_path.is_empty():
		_choices_panel = get_node(choices_panel_path) as CanvasItem


func _configure_line_text() -> void:
	if _line_text != null:
		_line_text.bbcode_enabled = true


func _cancel_full_presentation() -> void:
	_presentation_gen += 1
	_skip_typewriter = false
	_active_full_text = ""
	if _voice_player.playing:
		_voice_player.stop()
	if _speaker_label != null:
		_speaker_label.text = ""
	if _line_text != null:
		_line_text.text = ""
		_line_text.visible_characters = -1
	_clear_choices_presentation()


func _clear_choices_presentation() -> void:
	_clear_choice_buttons()
	_option_indices.clear()
	_selected_row = 0
	_choices_input_enabled = false


func _hide_panels() -> void:
	_set_panel_visible(_line_panel, false)
	_set_panel_visible(_choices_panel, false)


func _show_line_panel() -> void:
	_set_panel_visible(_line_panel, true)
	_set_panel_visible(_choices_panel, false)


func _show_choices_panel() -> void:
	_set_panel_visible(_line_panel, true)
	_set_panel_visible(_choices_panel, true)


func _set_panel_visible(panel: CanvasItem, visible: bool) -> void:
	if panel != null:
		panel.visible = visible


func _present_line(step: ConversationStep) -> void:
	_show_line_panel()
	if _speaker_label != null:
		_speaker_label.text = tr(step.speaker_id, "speakers")
	_active_full_text = step.text
	_skip_typewriter = false
	var generation: int = _presentation_gen
	_run_line_presentation(step, generation)


func _run_line_presentation(step: ConversationStep, generation: int) -> void:
	await _typewriter_reveal(step.text, generation)
	if generation != _presentation_gen:
		return
	await _handle_post_typewriter_tags(step, generation)
	if generation != _presentation_gen:
		return
	_active_full_text = ""
	ConversationController.notify_presentation_finished()


func _typewriter_reveal(full_text: String, generation: int) -> void:
	if _line_text == null:
		return
	_line_text.bbcode_text = full_text
	if _skip_typewriter or typewriter_char_delay <= 0.0:
		_line_text.visible_characters = -1
		return
	_line_text.visible_characters = 0
	var char_count: int = _line_text.get_total_character_count()
	for index: int in range(1, char_count + 1):
		if generation != _presentation_gen or _skip_typewriter:
			_line_text.visible_characters = -1
			return
		_line_text.visible_characters = index
		await get_tree().create_timer(typewriter_char_delay).timeout
	_line_text.visible_characters = -1


func _handle_post_typewriter_tags(step: ConversationStep, generation: int) -> void:
	var voice_path: String = _find_voice_path(step.tags)
	if not voice_path.is_empty():
		await _play_voice(voice_path, generation)
		return
	var time_seconds: float = _resolve_time_tag(step.tags, step.text)
	if time_seconds > 0.0:
		await get_tree().create_timer(time_seconds).timeout


func _find_voice_path(tags: PackedStringArray) -> String:
	for tag: String in tags:
		if tag.begins_with("voice="):
			return tag.substr("voice=".length())
	return ""


func _resolve_time_tag(tags: PackedStringArray, visible_text: String) -> float:
	for tag: String in tags:
		if tag == "time=auto":
			var plain_text: String = _strip_bbcode(visible_text)
			return clampf(
				float(plain_text.length()) * TIME_AUTO_CHARS_PER_SEC,
				TIME_AUTO_MIN,
				TIME_AUTO_MAX
			)
		if tag.begins_with("time="):
			var duration_text: String = tag.substr("time=".length())
			if duration_text.is_valid_float():
				return float(duration_text)
	return 0.0


func _strip_bbcode(text: String) -> String:
	return _bbcode_strip_regex.sub(text, "", true)


func _play_voice(path: String, generation: int) -> void:
	if not ResourceLoader.exists(path):
		push_warning("NativeDialoguePresenter: voice resource not found: %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("NativeDialoguePresenter: failed to load voice: %s" % path)
		return
	_voice_player.stream = stream
	_voice_player.play()
	while _voice_player.playing:
		if generation != _presentation_gen:
			return
		await get_tree().process_frame


func _present_choices(step: ConversationStep) -> void:
	_show_choices_panel()
	_option_indices.clear()
	var labels: Array[String] = []
	for option: Dictionary in step.options:
		labels.append(String(option.get("text", "")))
		_option_indices.append(int(option.get("index", _option_indices.size())))
	_build_choice_buttons(labels)
	_set_selected_row(0)
	_choices_input_enabled = false
	call_deferred("_enable_choices_input")


func _build_choice_buttons(labels: Array[String]) -> void:
	_clear_choice_buttons()
	if _choices_stack == null:
		return
	for row_index: int in labels.size():
		var button := Button.new()
		button.text = labels[row_index]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.custom_minimum_size = Vector2(260, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", _choice_style_normal)
		button.add_theme_stylebox_override("hover", _choice_style_hover)
		button.add_theme_stylebox_override("focus", _choice_style_selected)
		button.add_theme_stylebox_override("pressed", _choice_style_selected)
		var captured_row: int = row_index
		button.pressed.connect(func() -> void: _on_choice_button_pressed(captured_row))
		button.focus_entered.connect(func() -> void: _set_selected_row(captured_row))
		_choices_stack.add_child(button)
		_choice_buttons.append(button)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _clear_choice_buttons() -> void:
	_choice_buttons.clear()
	if _choices_stack != null:
		for child: Node in _choices_stack.get_children():
			child.queue_free()


func _set_selected_row(row_index: int) -> void:
	if _choice_buttons.is_empty():
		return
	_selected_row = clampi(row_index, 0, _choice_buttons.size() - 1)
	for index: int in _choice_buttons.size():
		var button: Button = _choice_buttons[index]
		var selected: bool = index == _selected_row
		button.add_theme_stylebox_override(
			"normal",
			_choice_style_selected if selected else _choice_style_normal
		)
		if selected and not button.has_focus():
			button.grab_focus()


func _enable_choices_input() -> void:
	_choices_input_enabled = true


func _on_choice_button_pressed(row_index: int) -> void:
	if not _choices_input_enabled:
		return
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingChoice:
		return
	_set_selected_row(row_index)
	if row_index < 0 or row_index >= _option_indices.size():
		return
	ConversationController.choose(_option_indices[row_index])


func _build_choice_styles() -> void:
	_choice_style_normal = _make_choice_style(_CHOICE_BG, Color.TRANSPARENT, 0.0)
	_choice_style_hover = _make_choice_style(_CHOICE_HOVER_BG, Color.TRANSPARENT, 0.0)
	_choice_style_selected = _make_choice_style(_CHOICE_SELECTED_BG, _CHOICE_BORDER, 2.0)


func _make_choice_style(bg: Color, border: Color, border_width: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(18)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	if border_width > 0.0:
		style.set_border_width_all(int(border_width))
		style.border_color = border
	return style
