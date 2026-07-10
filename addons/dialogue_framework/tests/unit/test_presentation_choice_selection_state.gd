extends GutTest


const UI_REACT_HUD_SCENE := (
	"res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn"
)
const CHOICE_SELECTED_STATE := (
	"res://addons/dialogue_framework/presentation/ui_states/choice_selected_state.tres"
)
const _UiReactButton := preload(
	"res://addons/ui_react/scripts/controls/ui_react_button.gd"
)


func before_each() -> void:
	TranslationServer.set_locale("en")
	_ensure_controller_idle()


func after_each() -> void:
	_ensure_controller_idle()


func _ensure_controller_idle() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		ConversationController.cancel()


func _choices_step() -> ConversationStep:
	var options: Array[Dictionary] = [
		ConversationStep.create_choice_option("Option A", "target_a", 0),
		ConversationStep.create_choice_option("Option B", "target_b", 1),
	]
	return ConversationStep.create_choices("choice_group", options, "after_choices")


func _instantiate_ui_react_hud() -> CanvasLayer:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	return hud


func test_ui_react_hud_navigate_choice_publishes_selected_state() -> void:
	var hud: CanvasLayer = _instantiate_ui_react_hud()
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var choice_state: UiIntState = load(CHOICE_SELECTED_STATE) as UiIntState
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	assert_eq(choice_state.get_value(), 0)
	presenter.navigate_choice(1)
	assert_eq(choice_state.get_value(), 1)


func test_ui_react_hud_choices_use_template_button() -> void:
	var hud: CanvasLayer = _instantiate_ui_react_hud()
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	assert_eq(choices_stack.get_child_count(), 2)
	var first_button: Button = choices_stack.get_child(0) as Button
	assert_not_null(first_button)
	assert_true(first_button.get_script() == _UiReactButton)
