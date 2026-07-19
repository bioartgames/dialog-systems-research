class_name DialoguePresenter
extends IDialoguePresenter

@export var hud_root_slot_path: NodePath
@export var speaker_slot_path: NodePath
@export var line_slot_path: NodePath
@export var choices_slot_path: NodePath
@export var line_panel_slot_path: NodePath
@export var choices_panel_slot_path: NodePath
@export var theme: DialoguePresentationTheme
@export var policy: DialoguePresentationPolicy

var _hud_root_slot: Node
var _speaker_slot: Node
var _line_slot: Node
var _choices_slot: Node
var _line_panel_slot: Node
var _choices_panel_slot: Node
var _voice_player: AudioStreamPlayer
var _choice_buttons: Array[Button] = []
var _option_indices: Array[int] = []
var _presentation_gen: int = 0
var _bbcode_strip_regex: RegEx
var _active_full_text: String = ""
var _skip_typewriter: bool = false
var _time_hold_active: bool = false
var _skip_time_hold: bool = false
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
	_resolve_slot_refs()
	_apply_presentation_resources()
	_hide_panels()


func present(step: ConversationStep) -> void:
	match step.kind:
		ConversationStepKind.Kind.LINE:
			_interrupt_active_line_presentation()
			_run_line_entry(step)
		ConversationStepKind.Kind.CHOICES:
			_clear_choices_presentation()
			_present_choices(step)


func dismiss() -> void:
	_presentation_gen += 1
	_cancel_active_line_presentation()
	_run_full_dismiss()


func refresh_line_text(step: ConversationStep) -> void:
	_call_slot(_speaker_slot, &"set_speaker_text", [tr(step.speaker_id, "speakers")])
	_call_line_slot(&"skip_to_full", [step.text])


func request_skip_typewriter() -> void:
	if _time_hold_active:
		_skip_time_hold = true
		return
	if _active_full_text.is_empty():
		return
	_skip_typewriter = true
	_call_line_slot(&"skip_to_full", [_active_full_text])


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


func _resolve_slot_refs() -> void:
	if not hud_root_slot_path.is_empty():
		_hud_root_slot = get_node(hud_root_slot_path)
	if not speaker_slot_path.is_empty():
		_speaker_slot = get_node(speaker_slot_path)
	if not line_slot_path.is_empty():
		_line_slot = get_node(line_slot_path)
	if not choices_slot_path.is_empty():
		_choices_slot = get_node(choices_slot_path)
	if not line_panel_slot_path.is_empty():
		_line_panel_slot = get_node(line_panel_slot_path)
	if not choices_panel_slot_path.is_empty():
		_choices_panel_slot = get_node(choices_panel_slot_path)


func _apply_presentation_resources() -> void:
	_call_slot(_speaker_slot, &"configure", [theme, policy])
	_call_slot(_line_slot, &"configure", [theme, policy])
	_call_slot(_line_panel_slot, &"configure", [theme, policy])
	_call_slot(_choices_panel_slot, &"configure", [theme, policy])
	_call_slot(_choices_slot, &"configure", [theme, policy])
	_build_choice_styles()


func _interrupt_active_line_presentation() -> void:
	_presentation_gen += 1
	_skip_typewriter = false
	_time_hold_active = false
	_skip_time_hold = false
	_active_full_text = ""
	if _voice_player.playing:
		_voice_player.stop()
	_call_line_slot(&"cancel_reveal")


func _cancel_active_line_presentation() -> void:
	_interrupt_active_line_presentation()
	_call_slot(_speaker_slot, &"clear")
	_call_slot(_line_slot, &"clear")


func _cancel_full_presentation() -> void:
	_cancel_active_line_presentation()
	_clear_choices_presentation()
	_call_slot(_choices_panel_slot, &"set_panel_visible", [false])


func _clear_choices_presentation() -> void:
	_clear_choice_buttons()
	_option_indices.clear()
	_selected_row = 0
	_call_slot(_choices_slot, &"set_selected_choice_index", [-1])
	_choices_input_enabled = false


func _hide_panels() -> void:
	_call_hud_root_slot(&"set_root_visible", [false])
	_call_slot(_line_panel_slot, &"set_panel_visible", [false])
	_call_slot(_choices_panel_slot, &"set_panel_visible", [false])


func _show_line_panel() -> void:
	_call_hud_root_slot(&"set_root_visible", [true])
	_call_slot(_line_panel_slot, &"set_panel_visible", [true])
	_call_slot(_choices_panel_slot, &"set_panel_visible", [false])


func _show_choices_panel() -> void:
	_call_hud_root_slot(&"set_root_visible", [true])
	_call_slot(_line_panel_slot, &"set_panel_visible", [true])
	_call_slot(_choices_panel_slot, &"set_panel_visible", [true])


func _dismiss_choices_panel_if_needed(generation: int) -> void:
	if generation != _presentation_gen:
		return
	if _choice_buttons.is_empty():
		return
	if _choices_panel_slot != null and _choices_panel_slot.has_method("dismiss_panel"):
		await _choices_panel_slot.call("dismiss_panel")
	else:
		_call_slot(_choices_panel_slot, &"set_panel_visible", [false])
	if generation != _presentation_gen:
		_force_hide_choices_immediate()
		return


func _force_hide_choices_immediate() -> void:
	_call_slot(_choices_panel_slot, &"set_panel_visible", [false])
	_clear_choices_presentation()


func _dismiss_line_panel_if_needed(generation: int) -> void:
	if generation != _presentation_gen:
		return
	if _line_panel_slot == null:
		return
	if not _line_panel_slot.has_method("is_panel_visible"):
		return
	if not bool(_line_panel_slot.call("is_panel_visible")):
		return
	if DialoguePresentationResourceApplier.line_dismiss_duration(policy) <= 0.0:
		return
	if not _line_panel_slot.has_method("dismiss_panel"):
		return
	await _line_panel_slot.call("dismiss_panel")
	if generation != _presentation_gen:
		return


func _run_line_entry(step: ConversationStep) -> void:
	var generation: int = _presentation_gen
	await _dismiss_choices_panel_if_needed(generation)
	if generation != _presentation_gen:
		return
	_clear_choices_presentation()
	_apply_presentation_resources()
	_show_line_panel()
	_call_slot(_speaker_slot, &"set_speaker_text", [tr(step.speaker_id, "speakers")])
	_active_full_text = step.text
	_skip_typewriter = false
	await _run_line_presentation(step, generation)


func _run_full_dismiss() -> void:
	var generation: int = _presentation_gen
	await _dismiss_choices_panel_if_needed(generation)
	if generation != _presentation_gen:
		return
	_clear_choices_presentation()
	await _dismiss_line_panel_if_needed(generation)
	if generation != _presentation_gen:
		return
	_hide_panels()


func _present_line(step: ConversationStep) -> void:
	_run_line_entry(step)


func _run_line_presentation(step: ConversationStep, generation: int) -> void:
	await _typewriter_reveal(step.text, generation)
	if generation != _presentation_gen:
		return
	await _handle_post_typewriter_tags(step, generation)
	if generation != _presentation_gen:
		return
	_finish_line_presentation(step)


func _finish_line_presentation(step: ConversationStep) -> void:
	_active_full_text = ""
	_time_hold_active = false
	ConversationController.notify_presentation_finished()
	if DialoguePresentationResourceApplier.should_auto_advance_after_time_tag(policy, step.tags):
		ConversationController.advance()


func _typewriter_reveal(full_text: String, generation: int) -> void:
	if _line_slot == null or not _line_slot.has_method("reveal_typewriter"):
		return
	var char_delay: float = DialoguePresentationResourceApplier.typewriter_delay(policy)
	if _skip_typewriter or char_delay <= 0.0:
		_call_line_slot(&"skip_to_full", [full_text])
		return
	await _line_slot.call("reveal_typewriter", full_text, char_delay, generation)


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
		await _await_time_hold(time_seconds, generation)


func _await_time_hold(seconds: float, generation: int) -> void:
	if seconds <= 0.0:
		return
	_time_hold_active = true
	_skip_time_hold = false
	var elapsed: float = 0.0
	while elapsed < seconds:
		if generation != _presentation_gen or _skip_time_hold:
			break
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_time_hold_active = false


func _strip_bbcode(text: String) -> String:
	return _bbcode_strip_regex.sub(text, "", true)


func _play_voice(path: String, generation: int) -> void:
	if not ResourceLoader.exists(path):
		push_warning("DialoguePresenter: voice resource not found: %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("DialoguePresenter: failed to load voice: %s" % path)
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
	var choices_stack: Container = _get_choice_container()
	if choices_stack == null:
		return
	var active_theme := DialoguePresentationResourceApplier.resolve_theme(theme, policy)
	for row_index: int in labels.size():
		var button: Button
		if _choices_slot != null and _choices_slot.has_method("create_choice_button"):
			button = _choices_slot.call("create_choice_button") as Button
		if button == null:
			button = Button.new()
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
		choices_stack.add_child(button)
		_choice_buttons.append(button)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()


func _get_choice_container() -> Container:
	if _choices_slot == null or not _choices_slot.has_method("get_choice_container"):
		return null
	return _choices_slot.call("get_choice_container") as Container


func _clear_choice_buttons() -> void:
	_choice_buttons.clear()
	var choices_stack: Container = _get_choice_container()
	if choices_stack != null:
		for child: Node in choices_stack.get_children():
			child.queue_free()


func _set_selected_row(row_index: int) -> void:
	if _choice_buttons.is_empty():
		return
	_selected_row = clampi(row_index, 0, _choice_buttons.size() - 1)
	_call_slot(_choices_slot, &"set_selected_choice_index", [_selected_row])
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
	_call_slot(_choices_slot, &"play_confirm_sfx")
	ConversationController.choose(_option_indices[row_index])


func _build_choice_styles() -> void:
	var styles: Dictionary = DialoguePresentationResourceApplier.build_choice_styles(
		DialoguePresentationResourceApplier.resolve_theme(theme, policy)
	)
	_choice_style_normal = styles["normal"]
	_choice_style_hover = styles["hover"]
	_choice_style_selected = styles["selected"]


func _call_slot(slot: Node, method: StringName, args: Array = []) -> void:
	if slot == null or not slot.has_method(method):
		return
	slot.callv(method, args)


func _call_line_slot(method: StringName, args: Array = []) -> void:
	_call_slot(_line_slot, method, args)


func _call_hud_root_slot(method: StringName, args: Array = []) -> void:
	_call_slot(_hud_root_slot, method, args)
