extends GutTest


const MIXED_HUD := (
	"res://addons/dialogue_framework/presentation/dialogue_hud_mixed_example.tscn"
)
const DIALOGUE_PRESENTER_PATH := (
	"res://addons/dialogue_framework/presentation/dialogue_presenter.gd"
)
const LINE_TEXT_STATE_PATH := (
	"res://addons/dialogue_framework/presentation/ui_states/line_text_state.tres"
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
	var source_text: String = "~ start\nRoll: Hello mixed layout.\n=> END\n"
	var result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://addons/dialogue_framework/tests/fixtures/mixed_hud_line.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func test_mixed_layout_uses_dialogue_presenter_without_ui_react_imports() -> void:
	if not ResourceLoader.exists(MIXED_HUD):
		pending("Mixed HUD scene unavailable")
		return
	var presenter_text: String = FileAccess.get_file_as_string(DIALOGUE_PRESENTER_PATH)
	assert_false(presenter_text.contains("res://addons/ui_react/"))
	var scene: PackedScene = load(MIXED_HUD)
	var hud: CanvasLayer = scene.instantiate()
	add_child_autofree(hud)
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	assert_not_null(presenter)
	assert_eq(presenter.get_script().resource_path, DIALOGUE_PRESENTER_PATH)
	var speaker_slot: Node = hud.get_node("HudRoot/LinePanel/VBox/SpeakerSlot")
	var line_slot: Node = hud.get_node("HudRoot/LinePanel/VBox/LineSlot")
	assert_true(speaker_slot.get_script().resource_path.ends_with("dialogue_speaker_slot.gd"))
	assert_true(line_slot.get_script().resource_path.ends_with("dialogue_line_slot_ui_react.gd"))


func test_mixed_layout_line_uses_ui_react_text_state_path() -> void:
	if not ResourceLoader.exists(MIXED_HUD):
		pending("Mixed HUD scene unavailable")
		return
	var scene: PackedScene = load(MIXED_HUD)
	var hud: CanvasLayer = scene.instantiate()
	add_child_autofree(hud)
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy.typewriter_char_delay = 0.0
	var line_state: UiStringState = load(LINE_TEXT_STATE_PATH) as UiStringState
	line_state.set_value("")
	await get_tree().process_frame
	var compiled: CompiledDialogue = _compile_line_dialogue()
	var context: GameContext = load(MOCK_CONTEXT_PATH).new()
	assert_true(ConversationController.start(compiled, "start", context, presenter))
	await wait_seconds(0.1)
	assert_eq(line_state.get_value(), "Hello mixed layout.")
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	assert_eq(speaker_label.text, "Roll")
