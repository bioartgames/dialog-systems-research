extends GutTest


const _HudRootSlot := preload(
	"res://addons/dialogue_framework/presentation/slots/dialogue_hud_root_slot.gd"
)


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


func test_line_panel_slot_applies_line_banner_chrome() -> void:
	var panel: PanelContainer = autofree(PanelContainer.new())
	var slot: DialoguePanelSlot = autofree(DialoguePanelSlot.new())
	slot.add_child(panel)
	slot.panel_path = NodePath(panel.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	var theme := DialoguePresentationTheme.new()
	theme.panel_bg_color = Color(1, 0, 0, 1)
	slot.configure(theme, DialoguePresentationPolicy.new())
	var panel_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(panel_style)
	assert_eq(panel_style.bg_color, Color(1, 0, 0, 1))


func test_choices_panel_slot_applies_choices_panel_chrome() -> void:
	var panel: PanelContainer = autofree(PanelContainer.new())
	var slot: DialoguePanelSlot = autofree(DialoguePanelSlot.new())
	slot.apply_line_panel_chrome = false
	slot.add_child(panel)
	slot.panel_path = NodePath(panel.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	var theme := DialoguePresentationTheme.new()
	theme.panel_bg_color = Color(1, 0, 0, 1)
	theme.choices_panel_bg_color = Color(0, 0, 0, 0)
	slot.configure(theme, DialoguePresentationPolicy.new())
	var panel_style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(panel_style)
	assert_eq(panel_style.bg_color, Color(0, 0, 0, 0))


func test_hud_root_slot_toggles_visibility() -> void:
	var root: Control = autofree(Control.new())
	var slot: Node = autofree(_HudRootSlot.new())
	slot.add_child(root)
	slot.root_path = NodePath(root.name)
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.set_root_visible(true)
	assert_true(root.visible)
	slot.set_root_visible(false)
	assert_false(root.visible)


func test_line_slot_uireact_skip_to_full_bbcode() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var text_state: UiStringState = autofree(UiStringState.new())
	var slot: DialogueLineSlotUiReact = autofree(DialogueLineSlotUiReact.new())
	slot.add_child(line_text)
	slot.line_text_path = NodePath(line_text.name)
	slot.text_state = text_state
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.skip_to_full("[b]Hi[/b]")
	assert_eq(line_text.get_parsed_text(), "Hi")
	assert_eq(text_state.get_value(), "[b]Hi[/b]")


func test_line_slot_uireact_typewriter_zero_delay() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var text_state: UiStringState = autofree(UiStringState.new())
	var slot: DialogueLineSlotUiReact = autofree(DialogueLineSlotUiReact.new())
	slot.add_child(line_text)
	slot.line_text_path = NodePath(line_text.name)
	slot.text_state = text_state
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.configure(DialoguePresentationTheme.new(), DialoguePresentationPolicy.new())
	await slot.reveal_typewriter("Hello", 0.0, 0)
	assert_eq(line_text.get_parsed_text(), "Hello")
	assert_eq(line_text.visible_characters, -1)
	assert_eq(text_state.get_value(), "Hello")


func test_line_slot_uireact_typewriter_no_raw_bbcode_mid_reveal() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var text_state: UiStringState = autofree(UiStringState.new())
	var slot: DialogueLineSlotUiReact = autofree(DialogueLineSlotUiReact.new())
	slot.add_child(line_text)
	slot.line_text_path = NodePath(line_text.name)
	slot.text_state = text_state
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.configure(DialoguePresentationTheme.new(), DialoguePresentationPolicy.new())
	slot.call("reveal_typewriter", "[b]Hi[/b]", 0.05, 0)
	await get_tree().create_timer(0.12).timeout
	var parsed: String = line_text.get_parsed_text()
	assert_false("[" in parsed)
	assert_false("]" in parsed)
	slot.cancel_reveal()
	await get_tree().create_timer(0.1).timeout


func test_line_slot_uireact_cancel_syncs_state() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var text_state: UiStringState = autofree(UiStringState.new())
	var slot: DialogueLineSlotUiReact = autofree(DialogueLineSlotUiReact.new())
	slot.add_child(line_text)
	slot.line_text_path = NodePath(line_text.name)
	slot.text_state = text_state
	add_child_autofree(slot)
	await get_tree().process_frame
	slot.call("reveal_typewriter", "Hello world", 0.1, 0)
	await get_tree().create_timer(0.05).timeout
	slot.cancel_reveal()
	await get_tree().create_timer(0.1).timeout
	assert_eq(text_state.get_value(), "Hello world")


const _ChoicesSlotUiReact := preload(
	"res://addons/dialogue_framework/presentation/slots/dialogue_choices_slot_ui_react.gd"
)
const _UiReactButton := preload(
	"res://addons/ui_react/scripts/controls/ui_react_button.gd"
)


func test_choices_slot_uireact_publishes_choice_selected_state() -> void:
	var state := UiIntState.new()
	var slot = autofree(_ChoicesSlotUiReact.new())
	slot.choice_selected_state = state
	slot.set_selected_choice_index(2)
	assert_eq(state.get_value(), 2)
	slot.set_selected_choice_index(-1)
	assert_eq(state.get_value(), -1)


func test_choices_slot_uireact_instantiates_template_scene() -> void:
	var scene: PackedScene = load(
		"res://addons/dialogue_framework/presentation/templates/choice_button_template.tscn"
	)
	var slot = autofree(_ChoicesSlotUiReact.new())
	slot.choice_button_scene = scene
	var button: Button = slot.create_choice_button()
	add_child_autofree(button)
	assert_not_null(button)
	assert_true(button.get_script() == _UiReactButton)
