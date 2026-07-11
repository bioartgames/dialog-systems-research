extends GutTest


const NATIVE_HUD_SCENE := (
	"res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn"
)
const UI_REACT_HUD_SCENE := (
	"res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn"
)


func before_each() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		ConversationController.cancel()


func after_each() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		ConversationController.cancel()


func _choices_step() -> ConversationStep:
	var options: Array[Dictionary] = [
		ConversationStep.create_choice_option("Option A", "target_a", 0),
		ConversationStep.create_choice_option("Option B", "target_b", 1),
	]
	return ConversationStep.create_choices("choice_group", options, "after_choices")


func _line_step() -> ConversationStep:
	return ConversationStep.create_line("line_1", "Roll", "Hello there.")


func _line_step_b() -> ConversationStep:
	return ConversationStep.create_line("line_2", "Roll", "Hear that bell.")


func test_ui_react_hud_dismiss_then_present_keeps_line_panel_visible() -> void:
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.line_dismiss_duration_sec = 0.15
	presenter.policy.choices_intro_duration_sec = 0.0
	presenter.policy.choices_dismiss_duration_sec = 0.0
	var line_panel: CanvasItem = hud.get_node("HudRoot/LinePanel") as CanvasItem
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	presenter.present(_line_step())
	await wait_seconds(0.05)
	assert_true(line_panel.visible)
	presenter.dismiss()
	presenter.present(_line_step_b())
	await wait_seconds(0.25)
	assert_true(line_panel.visible)
	assert_eq(line_text.get_parsed_text(), "Hear that bell.")


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


func test_ui_react_confirm_sfx_survives_choice_selection() -> void:
	var result: Dictionary = DialogueCompiler.compile_string(
		"~ start\nRoll: Pick one.\n- Option A => end_a\n~ end_a\nRoll: Done.\n=> END\n",
		"res://test/confirm_sfx.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var compiled: CompiledDialogue = result["compiled"]
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	var confirm_player: AudioStreamPlayer = (
		hud.get_node("HudRoot/ChoicesConfirmSfx") as AudioStreamPlayer
	)
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	await wait_seconds(0.05)
	ConversationController.notify_presentation_finished()
	ConversationController.advance()
	await wait_seconds(0.05)
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingChoice
	)
	presenter.confirm_selected_choice()
	await get_tree().process_frame
	assert_true(confirm_player.playing)
	assert_true(is_instance_valid(confirm_player))


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
