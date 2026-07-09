extends GutTest


func test_speaker_slot_sets_label_text() -> void:
	var label: Label = autofree(Label.new())
	var slot: DialogueSpeakerSlot = autofree(DialogueSpeakerSlot.new())
	slot.add_child(label)
	slot.speaker_label_path = NodePath(label.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.configure(DialoguePresentationTheme.new(), DialoguePresentationPolicy.new())
	slot.set_speaker_text("Roll")
	assert_eq(label.text, "Roll")
	slot.clear()
	assert_eq(label.text, "")


func test_line_slot_typewriter_zero_delay_shows_full_text() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var slot: DialogueLineSlot = autofree(DialogueLineSlot.new())
	slot.add_child(line_text)
	slot.line_text_path = NodePath(line_text.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.configure(DialoguePresentationTheme.new(), DialoguePresentationPolicy.new())
	await slot.reveal_typewriter("Hello", 0.0, 0)
	assert_eq(line_text.get_parsed_text(), "Hello")
	assert_eq(line_text.visible_characters, -1)


func test_line_slot_skip_to_full() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var slot: DialogueLineSlot = autofree(DialogueLineSlot.new())
	slot.add_child(line_text)
	slot.line_text_path = NodePath(line_text.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.skip_to_full("[b]Hi[/b]")
	assert_eq(line_text.get_parsed_text(), "Hi")


func test_panel_slot_visibility() -> void:
	var panel: PanelContainer = autofree(PanelContainer.new())
	var slot: DialoguePanelSlot = autofree(DialoguePanelSlot.new())
	slot.add_child(panel)
	slot.panel_path = NodePath(panel.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.set_panel_visible(true)
	assert_true(panel.visible)
	slot.clear()
	assert_false(panel.visible)


func test_choices_slot_returns_container() -> void:
	var stack: VBoxContainer = autofree(VBoxContainer.new())
	var slot: DialogueChoicesSlot = autofree(DialogueChoicesSlot.new())
	slot.add_child(stack)
	slot.choices_stack_path = NodePath(stack.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	assert_eq(slot.get_choice_container(), stack)
