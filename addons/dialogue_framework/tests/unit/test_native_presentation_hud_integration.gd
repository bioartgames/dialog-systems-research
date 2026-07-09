extends GutTest


const HUD_SCENE := "res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn"
const REDUCED_MOTION_POLICY := (
	"res://addons/dialogue_framework/presentation/resources/default_dialogue_policy_reduced_motion.tres"
)
const DIALOGUE_PRESENTER := preload(
	"res://addons/dialogue_framework/presentation/dialogue_presenter.gd"
)
const MOCK_CONTEXT_PATH := "res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"


func before_each() -> void:
	TranslationServer.set_locale("en")
	_ensure_controller_idle()


func after_each() -> void:
	_ensure_controller_idle()


func _ensure_controller_idle() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		ConversationController.cancel()


func _compile_line_dialogue() -> CompiledDialogue:
	var source_text: String = "~ start\nRoll: Hello there.\n=> END\n"
	var result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://addons/dialogue_framework/tests/fixtures/native_hud_line.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _instantiate_native_hud() -> CanvasLayer:
	var hud_scene: PackedScene = load(HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	return hud


func test_native_hud_loads_presenter_script() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: IDialoguePresenter = hud.get_node("Presenter") as IDialoguePresenter
	assert_not_null(presenter)
	assert_eq(presenter.get_script(), DIALOGUE_PRESENTER)


func test_native_hud_line_flow_updates_ui_and_reaches_awaiting_input() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: IDialoguePresenter = hud.get_node("Presenter") as IDialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	var line_panel: CanvasItem = hud.get_node("HudRoot/LinePanel") as CanvasItem
	var compiled: CompiledDialogue = _compile_line_dialogue()
	var context: GameContext = load(MOCK_CONTEXT_PATH).new()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	await wait_seconds(0.05)
	assert_eq(speaker_label.text, tr("Roll", "speakers"))
	assert_eq(line_text.get_parsed_text(), "Hello there.")
	assert_eq(line_text.visible_characters, -1)
	assert_true(line_panel.visible)
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingInput
	)


func test_native_hud_dismiss_clears_and_hides_ui() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: IDialoguePresenter = hud.get_node("Presenter") as IDialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	var line_panel: CanvasItem = hud.get_node("HudRoot/LinePanel") as CanvasItem
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	var compiled: CompiledDialogue = _compile_line_dialogue()
	var context: GameContext = load(MOCK_CONTEXT_PATH).new()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	await wait_seconds(0.05)
	presenter.dismiss()
	assert_eq(speaker_label.text, "")
	assert_eq(line_text.get_parsed_text(), "")
	assert_eq(line_text.visible_characters, -1)
	assert_false(line_panel.visible)
	assert_false(choices_panel.visible)


func _choices_step() -> ConversationStep:
	var options: Array[Dictionary] = [
		ConversationStep.create_choice_option("Option A", "target_a", 0),
		ConversationStep.create_choice_option("Option B", "target_b", 1),
	]
	return ConversationStep.create_choices("choice_group", options, "after_choices")


func test_native_hud_choices_present_populates_ui() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: IDialoguePresenter = hud.get_node("Presenter") as IDialoguePresenter
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	assert_true(choices_panel.visible)
	assert_eq(choices_stack.get_child_count(), 2)
	var first_button: Button = choices_stack.get_child(0) as Button
	var second_button: Button = choices_stack.get_child(1) as Button
	assert_eq(first_button.text, "Option A")
	assert_eq(second_button.text, "Option B")


func test_native_hud_choices_dismiss_clears_choices_panel() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: IDialoguePresenter = hud.get_node("Presenter") as IDialoguePresenter
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	var choices_stack: VBoxContainer = hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	presenter.dismiss()
	await get_tree().process_frame
	assert_false(choices_panel.visible)
	assert_eq(choices_stack.get_child_count(), 0)


func test_native_hud_loads_reduced_motion_policy_resource() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var reduced_policy: DialoguePresentationPolicy = load(REDUCED_MOTION_POLICY) as DialoguePresentationPolicy
	assert_not_null(reduced_policy)
	assert_true(reduced_policy.reduced_motion)
	assert_true(reduced_policy.skip_typewriter_when_reduced_motion)
	presenter.policy = reduced_policy
	assert_eq(presenter.policy, reduced_policy)
	assert_eq(presenter.get_script(), DIALOGUE_PRESENTER)


func test_native_hud_reduced_motion_policy_skips_typewriter() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var reduced_policy: DialoguePresentationPolicy = load(REDUCED_MOTION_POLICY) as DialoguePresentationPolicy
	reduced_policy.typewriter_char_delay = 0.25
	presenter.policy = reduced_policy
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	var compiled: CompiledDialogue = _compile_line_dialogue()
	var context: GameContext = load(MOCK_CONTEXT_PATH).new()
	var start_ms: int = Time.get_ticks_msec()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	var elapsed_ms: int = 0
	while elapsed_ms < 500:
		await get_tree().process_frame
		if (
			ConversationController.get_debug_state()["phase"]
			== ConversationPhase.Phase.AwaitingInput
		):
			break
		elapsed_ms = Time.get_ticks_msec() - start_ms
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingInput
	)
	assert_lt(elapsed_ms, 300, "Reduced-motion Policy should skip slow typewriter reveal")
	assert_eq(line_text.visible_characters, -1)


func test_native_hud_reduced_motion_runs_without_ui_react() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: Node = hud.get_node("Presenter")
	assert_true(presenter is DialoguePresenter)
	assert_eq(presenter.get_script(), DIALOGUE_PRESENTER)
	var reduced_policy: DialoguePresentationPolicy = load(REDUCED_MOTION_POLICY) as DialoguePresentationPolicy
	presenter.policy = reduced_policy
	assert_eq(DialoguePresentationResourceApplier.typewriter_delay(reduced_policy), 0.0)


func _expected_choices_stack_height(option_count: int, theme: DialoguePresentationTheme) -> float:
	if option_count <= 0:
		return 0.0
	var button_h: float = theme.choice_min_size.y
	var separation: int = theme.choice_separation
	return option_count * button_h + float(option_count - 1) * separation


func _single_choice_step() -> ConversationStep:
	var options: Array[Dictionary] = [
		ConversationStep.create_choice_option("Only", "target_a", 0),
	]
	return ConversationStep.create_choices("choice_group", options, "after")


func test_native_hud_choices_panel_height_tracks_option_count() -> void:
	var hud: CanvasLayer = await _instantiate_native_hud()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var choices_panel: PanelContainer = hud.get_node("HudRoot/ChoicesPanel") as PanelContainer
	var theme: DialoguePresentationTheme = presenter.theme as DialoguePresentationTheme
	assert_not_null(theme)
	presenter.present(_single_choice_step())
	await wait_seconds(0.05)
	await get_tree().process_frame
	var h1: float = choices_panel.size.y
	assert_lt(h1, 120.0)
	assert_almost_eq(h1, _expected_choices_stack_height(1, theme), 4.0)
	presenter.dismiss()
	await get_tree().process_frame
	presenter.present(_choices_step())
	await wait_seconds(0.05)
	await get_tree().process_frame
	var h2: float = choices_panel.size.y
	assert_gt(h2, h1)
	assert_almost_eq(h2, _expected_choices_stack_height(2, theme), 4.0)
