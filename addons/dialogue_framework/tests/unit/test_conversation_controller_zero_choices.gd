extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"


func _compile(source_text: String, path: String) -> CompiledDialogue:
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _mock_context() -> GameContext:
	return load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()


func _mock_presenter() -> IDialoguePresenter:
	var presenter: IDialoguePresenter = load(
		"res://addons/dialogue_framework/tests/helpers/mock_dialogue_presenter.gd"
	).new()
	add_child_autofree(presenter)
	return presenter


func _new_controller() -> Node:
	var controller: Node = load(CONTROLLER_PATH).new()
	add_child_autofree(controller)
	return controller


func test_zero_visible_choices_emits_conversation_ended_without_presenting_choices() -> void:
	var compiled: CompiledDialogue = _compile(
		(
			"~ start\n"
			+ "Roll: Pick one.\n"
			+ "- Hidden A | if flag(\"never_show\") => path_a\n"
			+ "- Hidden B | if flag(\"never_show\") => path_b\n"
			+ "\n"
			+ "~ path_a\n"
			+ "Roll: Path A.\n"
			+ "\n"
			+ "~ path_b\n"
			+ "Roll: Path B.\n"
		),
		"res://test/zero_visible_choices.dlg"
	)
	var context: GameContext = _mock_context()
	context.set_flag("never_show", false)
	var presenter: IDialoguePresenter = _mock_presenter()
	var controller: Node = _new_controller()
	watch_signals(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_eq(presenter.present_call_count, 1)
	assert_eq(presenter.last_step.kind, ConversationStepKind.Kind.LINE)
	controller.notify_presentation_finished()
	controller.advance()
	assert_push_warning("CHOICES step has zero visible options (D6.10).")
	assert_signal_emitted(controller, "conversation_ended")
	assert_eq(presenter.present_call_count, 1)
	assert_eq(controller.get_debug_state()["phase"], ConversationPhase.Phase.Idle)
