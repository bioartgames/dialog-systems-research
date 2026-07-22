extends GutTest

## IK-5 smoke: optional kit adoption path (D30.3 / D30.10).
## ResourceGameContext + CommandBridge + ConversationStarter + test-double presenter.


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


func _compile_fixture() -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func test_kit_adoption_start_cancel_with_bridge() -> void:
	var controller: Node = load(CONTROLLER_PATH).new()
	add_child_autofree(controller)
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	add_child_autofree(presenter)

	var starter = ConversationStarterScript.new()
	add_child_autofree(starter)
	starter.set_controller(controller)
	starter.presenter_path = starter.get_path_to(presenter)
	starter.compiled_dialogue = _compile_fixture()
	starter.entry_title = "start"
	starter.register_commands_on_ready = false

	var data = ResourceGameContextScript.new()
	data.display_values["hero_name"] = "Traveler"
	starter.context_resource = data

	var bridge = CommandBridgeScript.new()
	bridge.open_shop = false
	bridge.cutscene = false
	bridge.camera = false
	bridge.anim = false
	starter.command_bridge = bridge

	assert_true(starter.start_conversation())
	assert_eq(presenter.present_call_count, 1)
	assert_true(CommandRegistry.has_command("give_item"))
	assert_false(starter.start_conversation())  # already active

	starter.cancel_conversation()
	assert_eq(presenter.dismiss_call_count, 1)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)


func test_kit_replaceability_custom_context_without_runtime_fork() -> void:
	var controller: Node = load(CONTROLLER_PATH).new()
	add_child_autofree(controller)
	var presenter: IDialoguePresenter = MockPresenterScript.new()
	add_child_autofree(presenter)

	var starter = ConversationStarterScript.new()
	add_child_autofree(starter)
	starter.set_controller(controller)
	starter.presenter_path = starter.get_path_to(presenter)
	starter.compiled_dialogue = _compile_fixture()
	starter.register_commands_on_ready = false
	starter.context_resource = ResourceGameContextScript.new()

	var custom: GameContext = MockGameContextScript.new()
	custom.set_flag("kit_replace", true)
	starter.set_context(custom)

	assert_true(starter.start_conversation())
	assert_eq(custom.get_flag("kit_replace"), true)
	starter.cancel_conversation()
