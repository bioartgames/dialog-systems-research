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


func test_ui_react_hud_choices_open_does_not_delay_choices_visible() -> void:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.choices_intro_duration_sec = 0.3
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	presenter.present(_choices_step())
	await get_tree().process_frame
	assert_true(choices_panel.visible)
	assert_eq(choices_stack.get_child_count(), 2)


func test_ui_react_hud_line_dismiss_on_presenter_dismiss() -> void:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.line_dismiss_duration_sec = 0.2
	presenter.policy.choices_intro_duration_sec = 0.0
	presenter.policy.choices_dismiss_duration_sec = 0.0
	var line_panel: CanvasItem = hud.get_node("HudRoot/LinePanel") as CanvasItem
	presenter.present(_line_step())
	await wait_seconds(0.05)
	assert_true(line_panel.visible)
	presenter.dismiss()
	await wait_seconds(0.1)
	assert_true(line_panel.visible)
	await wait_seconds(0.15)
	assert_false(line_panel.visible)


func test_native_hud_line_dismiss_timer_on_dismiss() -> void:
	var hud_scene: PackedScene = load(NATIVE_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.line_dismiss_duration_sec = 0.2
	var line_panel: CanvasItem = hud.get_node("HudRoot/LinePanel") as CanvasItem
	presenter.present(_line_step())
	await wait_seconds(0.05)
	assert_true(line_panel.visible)
	presenter.dismiss()
	await wait_seconds(0.1)
	assert_true(line_panel.visible)
	await wait_seconds(0.15)
	assert_false(line_panel.visible)
