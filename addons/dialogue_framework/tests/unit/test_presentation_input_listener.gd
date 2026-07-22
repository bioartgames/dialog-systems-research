extends GutTest


const HUD_SCENE := "res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn"
const DEFAULT_INPUT := (
	"res://addons/dialogue_framework/presentation/resources/default_dialogue_input.tres"
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


func _make_accept_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_accept"
	event.pressed = true
	return event


func test_input_listener_can_be_disabled() -> void:
	var hud_scene: PackedScene = load(HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var listener := DialoguePresentationInputListener.new()
	listener.input = load(DEFAULT_INPUT) as DialoguePresentationInput
	listener.presenter_path = NodePath("../Presenter")
	hud.add_child(listener)
	await get_tree().process_frame
	var compiled: CompiledDialogue = _compile_line_dialogue()
	var context: GameContext = load(MOCK_CONTEXT_PATH).new()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	await wait_seconds(0.05)
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingInput
	)
	listener.set_listening_enabled(false)
	listener._unhandled_input(_make_accept_event())
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.AwaitingInput
	)


func test_input_listener_advances_line_on_advance_action() -> void:
	var hud_scene: PackedScene = load(HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var listener: DialoguePresentationInputListener = hud.get_node("InputListener") as DialoguePresentationInputListener
	await get_tree().process_frame
	var compiled: CompiledDialogue = _compile_line_dialogue()
	var context: GameContext = load(MOCK_CONTEXT_PATH).new()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	await wait_seconds(0.05)
	listener._unhandled_input(_make_accept_event())
	await wait_seconds(0.05)
	assert_eq(
		ConversationController.get_debug_state()["phase"],
		ConversationPhase.Phase.Idle
	)


func test_input_listener_skips_typewriter_during_line_presentation() -> void:
	var hud_scene: PackedScene = load(HUD_SCENE)
	var hud: CanvasLayer = hud_scene.instantiate()
	add_child_autofree(hud)
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.5
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	var listener := DialoguePresentationInputListener.new()
	listener.input = load(DEFAULT_INPUT) as DialoguePresentationInput
	listener.presenter_path = NodePath("../Presenter")
	hud.add_child(listener)
	await get_tree().process_frame
	var compiled: CompiledDialogue = _compile_line_dialogue()
	var context: GameContext = load(MOCK_CONTEXT_PATH).new()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	await wait_seconds(0.05)
	listener._unhandled_input(_make_accept_event())
	await wait_seconds(0.05)
	assert_eq(line_text.get_parsed_text(), "Hello there.")
	assert_eq(line_text.visible_characters, -1)
