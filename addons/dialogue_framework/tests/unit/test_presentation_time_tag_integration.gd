extends GutTest


const UI_REACT_HUD_SCENE := (
	"res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn"
)


func before_each() -> void:
	_ensure_controller_idle()


func after_each() -> void:
	_ensure_controller_idle()


func _ensure_controller_idle() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		ConversationController.cancel()


func _compile(source_text: String) -> CompiledDialogue:
	var result: Dictionary = DialogueCompiler.compile_string(
		source_text, "res://test/time_tag.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _mock_context() -> GameContext:
	return load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()


func _start_conversation(source: String, policy_overrides: Dictionary = {}) -> Dictionary:
	_ensure_controller_idle()
	var compiled: CompiledDialogue = _compile(source)
	var hud_scene: PackedScene = load(UI_REACT_HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	presenter.policy.time_auto_min_seconds = 0.05
	presenter.policy.time_auto_chars_per_sec = 0.01
	for key: String in policy_overrides:
		presenter.policy.set(key, policy_overrides[key])
	var context: GameContext = _mock_context()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	return {"hud": hud, "presenter": presenter}


func test_time_auto_advances_to_choices_without_extra_press() -> void:
	var setup: Dictionary = await _start_conversation(
		"~ start\nRoll: Hello #time=auto\n- Option A => end_a\n- Option B => end_b\n\n~ end_a\nRoll: Done A.\n=> END\n\n~ end_b\nRoll: Done B.\n=> END\n"
	)
	var hud: CanvasLayer = setup["hud"]
	var choices_stack: VBoxContainer = (
		hud.get_node("HudRoot/ChoicesPanel/ChoicesStack") as VBoxContainer
	)
	var choices_panel: CanvasItem = hud.get_node("HudRoot/ChoicesPanel") as CanvasItem
	await wait_seconds(0.15)
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingChoice
	)
	assert_true(choices_panel.visible)
	assert_eq(choices_stack.get_child_count(), 2)


func test_time_numeric_waits_for_accept_after_hold() -> void:
	await _start_conversation(
		"~ start\nRoll: Hello #time=0.1\n- Option A => end_a\n- Option B => end_b\n\n~ end_a\nRoll: Done A.\n=> END\n\n~ end_b\nRoll: Done B.\n=> END\n"
	)
	await wait_seconds(0.15)
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingInput
	)
	ConversationController.advance()
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingChoice
	)


func test_skip_during_time_auto_hold_advances_immediately() -> void:
	var setup: Dictionary = await _start_conversation(
		"~ start\nRoll: Hello #time=auto\n- Option A => end_a\n- Option B => end_b\n\n~ end_a\nRoll: Done A.\n=> END\n\n~ end_b\nRoll: Done B.\n=> END\n",
		{"time_auto_min_seconds": 2.0}
	)
	var presenter: DialoguePresenter = setup["presenter"]
	await get_tree().process_frame
	presenter.request_skip_typewriter()
	await get_tree().process_frame
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingChoice
	)


func test_skip_during_time_numeric_hold_finishes_to_awaiting_input() -> void:
	var setup: Dictionary = await _start_conversation(
		"~ start\nRoll: Hello #time=2.0\n- Option A => end_a\n- Option B => end_b\n\n~ end_a\nRoll: Done A.\n=> END\n\n~ end_b\nRoll: Done B.\n=> END\n"
	)
	var presenter: DialoguePresenter = setup["presenter"]
	await get_tree().process_frame
	presenter.request_skip_typewriter()
	await get_tree().process_frame
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingInput
	)
