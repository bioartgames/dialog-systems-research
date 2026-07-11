class_name DialogueLineReveal
extends RefCounted


static func ensure_bbcode_enabled(line_text: RichTextLabel) -> void:
	if line_text != null:
		line_text.bbcode_enabled = true


static func clear(line_text: RichTextLabel) -> void:
	if line_text == null:
		return
	line_text.text = ""
	line_text.visible_characters = -1


static func skip_to_full(line_text: RichTextLabel, full_bbcode: String) -> void:
	if line_text == null:
		return
	line_text.bbcode_text = full_bbcode
	line_text.visible_characters = -1


static func reveal_typewriter(
	line_text: RichTextLabel,
	full_bbcode: String,
	char_delay: float,
	is_cancelled: Callable,
	tree: SceneTree
) -> void:
	if line_text == null:
		return
	line_text.bbcode_text = full_bbcode
	if char_delay <= 0.0:
		line_text.visible_characters = -1
		return
	line_text.visible_characters = 0
	var char_count: int = line_text.get_total_character_count()
	for index: int in range(1, char_count + 1):
		if not is_instance_valid(line_text):
			return
		if is_cancelled.is_valid() and is_cancelled.call():
			return
		line_text.visible_characters = index
		await tree.create_timer(char_delay).timeout
	if is_instance_valid(line_text):
		line_text.visible_characters = -1
