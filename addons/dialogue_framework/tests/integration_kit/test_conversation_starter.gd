extends GutTest


const ConversationStarterScript := preload(
	"res://addons/dialogue_framework/integration/conversation_starter.gd"
)
const ResourceGameContextScript := preload(
	"res://addons/dialogue_framework/integration/resource_game_context.gd"
)
const CommandBridgeScript := preload(
	"res://addons/dialogue_framework/integration/command_bridge.gd"
)
const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"
const MockPresenterScript := preload(
	"res://addons/dialogue_framework/tests/helpers/mock_dialogue_presenter.gd"
)
const MockGameContextScript := preload(
	"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
)


func before_each() -> void:
	CommandRegistry.clear_for_tests()


func _compile_fixture(path: String = FIXTURE_PATH) -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(path)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _new_controller() -> Node:
	var controller: Node = load(CONTROLLER_PATH).new()
	add_child_autofree(controller)
	return controller


func _build_starter(
	controller: Node,
	presenter: IDialoguePresenter,
	compiled: CompiledDialogue = null
):
	var starter = ConversationStarterScript.new()
	add_child_autofree(starter)
	add_child_autofree(presenter)
	starter.set_controller(controller)
	starter.presenter_path = starter.get_path_to(presenter)
	starter.entry_title = "start"
	starter.register_commands_on_ready = false
	if compiled != null:
		starter.compiled_dialogue = compiled
	return starter


func test_start_conversation_with_resource_context_and_presenter_path() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var controller: Node = _new_controller()
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	var starter = _build_starter(controller, presenter, compiled)
	var data = ResourceGameContextScript.new()
	starter.context_resource = data

	assert_true(starter.start_conversation())
	assert_eq(presenter.present_call_count, 1)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.LINE)


func test_start_conversation_with_injected_custom_context() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var controller: Node = _new_controller()
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	var starter = _build_starter(controller, presenter, compiled)
	var custom: GameContext = MockGameContextScript.new()
	custom.set_flag("from_custom", true)
	starter.set_context(custom)

	assert_true(starter.start_conversation())
	assert_eq(custom.get_flag("from_custom"), true)


func test_optional_bridge_registers_before_start() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var controller: Node = _new_controller()
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	var starter = _build_starter(controller, presenter, compiled)
	var data = ResourceGameContextScript.new()
	starter.context_resource = data
	var bridge = CommandBridgeScript.new()
	bridge.open_shop = false
	bridge.cutscene = false
	bridge.camera = false
	bridge.anim = false
	starter.command_bridge = bridge

	assert_false(CommandRegistry.has_command("start_quest"))
	assert_true(starter.start_conversation())
	assert_true(CommandRegistry.has_command("start_quest"))
	await CommandRegistry.dispatch("start_quest", PackedStringArray(["intro"]))
	assert_eq(String(data.quest_states.get("intro", "")), "active")


func test_cancel_conversation_calls_controller() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var controller: Node = _new_controller()
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	var starter = _build_starter(controller, presenter, compiled)
	starter.context_resource = ResourceGameContextScript.new()

	assert_true(starter.start_conversation())
	starter.cancel_conversation()
	assert_eq(presenter.dismiss_call_count, 1)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)


func test_start_fails_without_presenter_path() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var controller: Node = _new_controller()
	var starter = ConversationStarterScript.new()
	add_child_autofree(starter)
	starter.set_controller(controller)
	starter.compiled_dialogue = compiled
	starter.context_resource = ResourceGameContextScript.new()
	starter.register_commands_on_ready = false

	assert_false(starter.start_conversation())
	assert_push_error("presenter_path")


func test_start_loads_compiled_via_dialogue_path() -> void:
	var controller: Node = _new_controller()
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	var starter = _build_starter(controller, presenter, null)
	starter.context_resource = ResourceGameContextScript.new()
	starter.dialogue_path = FIXTURE_PATH
	assert_true(starter.start_conversation())
	assert_eq(presenter.present_call_count, 1)


func test_start_fails_without_compiled_source() -> void:
	var controller: Node = _new_controller()
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	var starter = _build_starter(controller, presenter, null)
	starter.context_resource = ResourceGameContextScript.new()
	starter.dialogue_path = ""
	assert_false(starter.start_conversation())
	assert_push_error("CompiledDialogue")


func test_start_fails_without_context() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var controller: Node = _new_controller()
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	var starter = _build_starter(controller, presenter, compiled)
	assert_false(starter.start_conversation())
	assert_push_error("GameContext")
