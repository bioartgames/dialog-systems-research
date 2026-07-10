extends GutTest


const NATIVE_HUD_SCENE := (
	"res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn"
)
const UI_REACT_HUD_SCENE := (
	"res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn"
)


func _choices_step() -> ConversationStep:
	var options: Array[Dictionary] = [
		ConversationStep.create_choice_option("Option A", "target_a", 0),
		ConversationStep.create_choice_option("Option B", "target_b", 1),
	]
	return ConversationStep.create_choices("choice_group", options, "after_choices")


func _line_step() -> ConversationStep:
	return ConversationStep.create_line("line_1", "Roll", "Hello there.")


func _prompting_line_step() -> ConversationStep:
	return ConversationStep.create_line("line_1", "Roll", "Where next, Traveler?")


func test_native_hud_preserves_line_when_choices_appear() -> void:
	var hud_scene: PackedScene = load(NATIVE_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	var line_panel: CanvasItem = hud.get_node("HudRoot/LinePanel") as CanvasItem
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_prompting_line_step())
	await wait_seconds(0.05)
	presenter.present(_choices_step())
	await get_tree().process_frame
	assert_true(line_panel.visible)
	assert_true(choices_panel.visible)
	assert_eq(speaker_label.text, tr("Roll", "speakers"))
	assert_eq(line_text.get_parsed_text(), "Where next, Traveler?")
	assert_eq(choices_stack.get_child_count(), 2)


func test_ui_react_hud_preserves_line_when_choices_appear() -> void:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	var line_panel: CanvasItem = hud.get_node("HudRoot/LinePanel") as CanvasItem
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_prompting_line_step())
	await wait_seconds(0.05)
	presenter.present(_choices_step())
	await get_tree().process_frame
	assert_true(line_panel.visible)
	assert_true(choices_panel.visible)
	assert_eq(speaker_label.text, tr("Roll", "speakers"))
	assert_eq(line_text.get_parsed_text(), "Where next, Traveler?")
	assert_eq(choices_stack.get_child_count(), 2)


func test_ui_react_hud_defers_choice_clear_until_dismiss_elapsed() -> void:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.choices_dismiss_duration_sec = 0.15
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	assert_eq(choices_stack.get_child_count(), 2)
	presenter.present(_line_step())
	assert_eq(choices_stack.get_child_count(), 2)
	await wait_seconds(0.08)
	assert_eq(choices_stack.get_child_count(), 2)
	await wait_seconds(0.1)
	assert_eq(choices_stack.get_child_count(), 0)


func test_ui_react_hud_choices_panel_visible_during_policy_dismiss() -> void:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.choices_dismiss_duration_sec = 0.2
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	presenter.present(_line_step())
	await wait_seconds(0.05)
	assert_true(choices_panel.visible)
	assert_eq(choices_stack.get_child_count(), 2)
	await wait_seconds(0.07)
	assert_true(choices_panel.visible)
	assert_eq(choices_stack.get_child_count(), 2)
	await wait_seconds(0.13)
	assert_eq(choices_stack.get_child_count(), 0)


func test_ui_react_hud_preserves_prompting_line_during_choice_to_line_dismiss() -> void:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	presenter.present(_prompting_line_step())
	await wait_seconds(0.05)
	presenter.present(_choices_step())
	await get_tree().process_frame
	presenter.present(_line_step())
	await get_tree().process_frame
	assert_eq(speaker_label.text, tr("Roll", "speakers"))
	assert_eq(line_text.get_parsed_text(), "Where next, Traveler?")
	await wait_seconds(0.08)
	assert_eq(speaker_label.text, tr("Roll", "speakers"))
	assert_eq(line_text.get_parsed_text(), "Where next, Traveler?")
	await wait_seconds(0.15)
	assert_eq(line_text.get_parsed_text(), "Hello there.")


func test_native_hud_preserves_prompting_line_during_choice_to_line_dismiss() -> void:
	var hud_scene: PackedScene = load(NATIVE_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	presenter.policy.choices_dismiss_duration_sec = 0.15
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	presenter.present(_prompting_line_step())
	await wait_seconds(0.05)
	presenter.present(_choices_step())
	await get_tree().process_frame
	presenter.present(_line_step())
	await get_tree().process_frame
	assert_eq(speaker_label.text, tr("Roll", "speakers"))
	assert_eq(line_text.get_parsed_text(), "Where next, Traveler?")
	await wait_seconds(0.08)
	assert_eq(speaker_label.text, tr("Roll", "speakers"))
	assert_eq(line_text.get_parsed_text(), "Where next, Traveler?")
	await wait_seconds(0.15)
	assert_eq(line_text.get_parsed_text(), "Hello there.")


func test_native_hud_dismiss_still_instant_with_default_policy() -> void:
	var hud_scene: PackedScene = load(NATIVE_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	assert_eq(choices_stack.get_child_count(), 2)
	presenter.present(_line_step())
	await get_tree().process_frame
	assert_eq(choices_stack.get_child_count(), 0)
