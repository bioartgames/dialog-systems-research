class_name NativeDialoguePresenter
extends IDialoguePresenter

@export var speaker_label_path: NodePath
@export var line_text_path: NodePath
@export var choices_stack_path: NodePath
@export var line_panel_path: NodePath
@export var choices_panel_path: NodePath
@export var theme: DialoguePresentationTheme
@export var policy: DialoguePresentationPolicy
@export var input: DialoguePresentationInput

var _speaker_label: Label
var _line_text: RichTextLabel
var _choices_stack: VBoxContainer
var _line_panel: PanelContainer
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
	_apply_presentation_resources()
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
	var next_row: int = _selected_row + delta
	var active_policy := DialoguePresentationResourceApplier.resolve_policy(policy)
	if active_policy.wrap_choice_navigation:
		_set_selected_row(wrapi(next_row, 0, row_count))
	else:
		_set_selected_row(clampi(next_row, 0, row_count - 1))


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
		_line_panel = get_node(line_panel_path) as PanelContainer
	if not choices_panel_path.is_empty():
		_choices_panel = get_node(choices_panel_path) as CanvasItem


func _configure_line_text() -> void:
	if _line_text != null:
		_line_text.bbcode_enabled = true


func _apply_presentation_resources() -> void:
	DialoguePresentationResourceApplier.apply_native_line_theme(
		theme,
		_speaker_label,
		_line_text,
		_line_panel,
		_choices_stack,
		policy
	)
	_build_choice_styles()


func _apply_line_overflow() -> void:
	DialoguePresentationResourceApplier.apply_line_overflow(policy, _line_text)


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
	_apply_presentation_resources()
	_apply_line_overflow()
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
	var char_delay: float = DialoguePresentationResourceApplier.typewriter_delay(policy)
	if _skip_typewriter or char_delay <= 0.0:
		_line_text.visible_characters = -1
		return
	_line_text.visible_characters = 0
	var char_count: int = _line_text.get_total_character_count()
	for index: int in range(1, char_count + 1):
		if generation != _presentation_gen or _skip_typewriter:
			_line_text.visible_characters = -1
			return
		_line_text.visible_characters = index
		await get_tree().create_timer(char_delay).timeout
	_line_text.visible_characters = -1


func _handle_post_typewriter_tags(step: ConversationStep, generation: int) -> void:
	var voice_path: String = DialoguePresentationResourceApplier.find_voice_path(policy, step.tags)
	if not voice_path.is_empty():
		await _play_voice(voice_path, generation)
		return
	var time_seconds: float = DialoguePresentationResourceApplier.resolve_time_tag(
		policy,
		step.tags,
		step.text,
		Callable(self, "_strip_bbcode")
	)
	if time_seconds > 0.0:
		await get_tree().create_timer(time_seconds).timeout


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
	_apply_presentation_resources()
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
	var active_theme := DialoguePresentationResourceApplier.resolve_theme(theme, policy)
	for row_index: int in labels.size():
		var button := Button.new()
		button.text = labels[row_index]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.custom_minimum_size = active_theme.choice_min_size
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
	var styles: Dictionary = DialoguePresentationResourceApplier.build_choice_styles(
		DialoguePresentationResourceApplier.resolve_theme(theme, policy)
	)
	_choice_style_normal = styles["normal"]
	_choice_style_hover = styles["hover"]
	_choice_style_selected = styles["selected"]
