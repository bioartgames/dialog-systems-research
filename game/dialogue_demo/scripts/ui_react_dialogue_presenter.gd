class_name UiReactDialoguePresenter
extends IDialoguePresenter

const TYPEWRITER_CHAR_DELAY: float = 0.03
const TIME_AUTO_CHARS_PER_SEC: float = 0.02
const TIME_AUTO_MIN: float = 0.5
const TIME_AUTO_MAX: float = 8.0

@export var speaker_state: UiStringState
@export var line_text_state: UiStringState
@export var choices_items_state: UiArrayState
@export var hud_visible_state: UiBoolState
@export var line_panel_visible_state: UiBoolState
@export var choices_panel_visible_state: UiBoolState
@export var choices_list_path: NodePath
@export var typewriter_char_delay: float = TYPEWRITER_CHAR_DELAY

var _voice_player: AudioStreamPlayer
var _choices_list: ItemList
var _option_indices: Array[int] = []
var _presentation_gen: int = 0
var _bbcode_strip_regex: RegEx


func _ready() -> void:
	_bbcode_strip_regex = RegEx.new()
	_bbcode_strip_regex.compile("\\[/?[^\\]]+\\]")
	_voice_player = AudioStreamPlayer.new()
	add_child(_voice_player)
	if not choices_list_path.is_empty():
		_choices_list = get_node(choices_list_path) as ItemList
		if _choices_list != null:
			_choices_list.item_selected.connect(_on_choice_selected)
	_hide_hud()


func present(step: ConversationStep) -> void:
	_cancel_active_presentation()
	match step.kind:
		ConversationStepKind.Kind.LINE:
			_present_line(step)
		ConversationStepKind.Kind.CHOICES:
			_present_choices(step)


func dismiss() -> void:
	_cancel_active_presentation()
	_hide_hud()


func _cancel_active_presentation() -> void:
	_presentation_gen += 1
	if _voice_player.playing:
		_voice_player.stop()
	if line_text_state != null:
		line_text_state.set_value("")
	if speaker_state != null:
		speaker_state.set_value("")
	if choices_items_state != null:
		choices_items_state.set_value([])
	_option_indices.clear()


func _hide_hud() -> void:
	_set_bool_state(hud_visible_state, false)
	_set_bool_state(line_panel_visible_state, false)
	_set_bool_state(choices_panel_visible_state, false)


func _show_line_hud() -> void:
	_set_bool_state(hud_visible_state, true)
	_set_bool_state(line_panel_visible_state, true)
	_set_bool_state(choices_panel_visible_state, false)


func _show_choices_hud() -> void:
	_set_bool_state(hud_visible_state, true)
	_set_bool_state(line_panel_visible_state, false)
	_set_bool_state(choices_panel_visible_state, true)


func _set_bool_state(state: UiBoolState, value: bool) -> void:
	if state != null:
		state.set_value(value)


func _present_line(step: ConversationStep) -> void:
	_show_line_hud()
	_option_indices.clear()
	if speaker_state != null:
		speaker_state.set_value(tr(step.speaker_id, "speakers"))
	if line_text_state != null:
		line_text_state.set_value("")
	var generation: int = _presentation_gen
	_run_line_presentation(step, generation)


func _run_line_presentation(step: ConversationStep, generation: int) -> void:
	await _typewriter_reveal(step.text, generation)
	if generation != _presentation_gen:
		return
	await _handle_post_typewriter_tags(step, generation)
	if generation != _presentation_gen:
		return
	ConversationController.notify_presentation_finished()


func _typewriter_reveal(full_text: String, generation: int) -> void:
	if line_text_state == null:
		return
	var revealed: String = ""
	for index: int in full_text.length():
		if generation != _presentation_gen:
			return
		revealed = full_text.substr(0, index + 1)
		line_text_state.set_value(revealed)
		if typewriter_char_delay > 0.0:
			await get_tree().create_timer(typewriter_char_delay).timeout
		else:
			await get_tree().process_frame


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
		push_warning("UiReactDialoguePresenter: voice resource not found: %s" % path)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("UiReactDialoguePresenter: failed to load voice: %s" % path)
		return
	_voice_player.stream = stream
	_voice_player.play()
	while _voice_player.playing:
		if generation != _presentation_gen:
			return
		await get_tree().process_frame


func _present_choices(step: ConversationStep) -> void:
	_show_choices_hud()
	_option_indices.clear()
	var items: Array = []
	for option: Dictionary in step.options:
		items.append(String(option.get("text", "")))
		_option_indices.append(int(option.get("index", items.size() - 1)))
	if choices_items_state != null:
		choices_items_state.set_value(items)


func _on_choice_selected(row_index: int) -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingChoice:
		return
	if row_index < 0 or row_index >= _option_indices.size():
		return
	ConversationController.choose(_option_indices[row_index])
