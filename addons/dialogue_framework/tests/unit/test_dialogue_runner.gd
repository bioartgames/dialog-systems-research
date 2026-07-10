extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"
const BRANCHING_FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/branching.dlg"
const BRANCHING_EXIT_FIXTURE_PATH := (
	"res://addons/dialogue_framework/tests/fixtures/branching_exit.dlg"
)


func _compile_fixture(path: String = FIXTURE_PATH) -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(path)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _mock_context() -> GameContext:
	return load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()


func test_load_and_init_from_title_peeks_first_line_after_title() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	assert_eq(runner.peek_step_kind(), ConversationStepKind.Kind.LINE)


func test_set_cursor_and_peek_line_kind() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var title_line_id: String = compiled.get_title_line_id("start")
	var dialogue_line_id: String = String(
		compiled.get_line(title_line_id).get(CompiledLine.KEY_NEXT_ID, "")
	)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_cursor(dialogue_line_id)
	assert_eq(runner.peek_step_kind(), ConversationStepKind.Kind.LINE)


func test_peek_choice_kind_at_choice_line() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var choice_line_id: String = ""
	for line_id: String in compiled.lines:
		if CompiledLine.get_kind(compiled.lines[line_id]) == LineKind.Kind.CHOICE:
			choice_line_id = line_id
			break
	assert_false(choice_line_id.is_empty())
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_cursor(choice_line_id)
	assert_eq(runner.peek_step_kind(), ConversationStepKind.Kind.CHOICES)


func test_peek_returns_end_for_invalid_cursor() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_cursor("missing_line_id")
	assert_eq(runner.peek_step_kind(), ConversationStepKind.Kind.END)


func test_build_step_at_cursor_returns_line_without_advancing() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var title_line_id: String = compiled.get_title_line_id("start")
	var dialogue_line_id: String = String(
		compiled.get_line(title_line_id).get(CompiledLine.KEY_NEXT_ID, "")
	)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_cursor(dialogue_line_id)
	var step: ConversationStep = runner.build_step_at_cursor()
	assert_not_null(step)
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "Hello there.")
	assert_eq(runner.get_cursor_line_id(), dialogue_line_id)


func test_next_step_yields_line_after_skipping_title() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	var step: ConversationStep = runner.next_step()
	assert_not_null(step)
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "Hello there.")


func test_branching_follows_true_condition_branch() -> void:
	var compiled: CompiledDialogue = _compile_fixture(BRANCHING_FIXTURE_PATH)
	var context: GameContext = _mock_context()
	context.set_flag("met_roll", true)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_game_context(context)
	runner.init_from_title("branch")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.text, "Good to see you again.")


func test_branching_follows_false_condition_branch() -> void:
	var compiled: CompiledDialogue = _compile_fixture(BRANCHING_FIXTURE_PATH)
	var context: GameContext = _mock_context()
	context.set_flag("met_roll", false)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_game_context(context)
	runner.init_from_title("branch")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.text, "Who are you?")


func test_branching_true_branch_does_not_show_else_on_advance() -> void:
	var compiled: CompiledDialogue = _compile_fixture(BRANCHING_FIXTURE_PATH)
	var context: GameContext = _mock_context()
	context.set_flag("met_roll", true)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_game_context(context)
	runner.init_from_title("branch")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.text, "Good to see you again.")
	assert_null(runner.next_step())


func test_true_branch_does_not_fall_through_to_else_body() -> void:
	var compiled: CompiledDialogue = _compile_fixture(BRANCHING_EXIT_FIXTURE_PATH)
	var context: GameContext = _mock_context()
	context.set_flag("branch_a", true)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_game_context(context)
	runner.init_from_title("branch_with_choices")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "True line one.")
	step = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "True line two.")
	step = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.CHOICES)


func test_false_branch_reaches_choices_after_else() -> void:
	var compiled: CompiledDialogue = _compile_fixture(BRANCHING_EXIT_FIXTURE_PATH)
	var context: GameContext = _mock_context()
	context.set_flag("branch_a", false)
	context.set_flag("branch_b", false)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_game_context(context)
	runner.init_from_title("branch_with_choices")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "Else line.")
	step = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.CHOICES)


func test_elif_branch_reaches_choices_not_else() -> void:
	var compiled: CompiledDialogue = _compile_fixture(BRANCHING_EXIT_FIXTURE_PATH)
	var context: GameContext = _mock_context()
	context.set_flag("branch_a", false)
	context.set_flag("branch_b", true)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_game_context(context)
	runner.init_from_title("branch_with_choices")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "Elif line.")
	step = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.CHOICES)


func test_goto_skips_to_target_title_line() -> void:
	var source_text: String = (
		"~ start\n"
		+ "=> shop\n"
		+ "\n"
		+ "~ shop\n"
		+ "Roll: Welcome.\n"
	)
	var compiled: CompiledDialogue
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/goto_runtime.dlg"
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
	compiled = compile_result["compiled"]
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "Welcome.")


func test_next_step_yields_end_at_explicit_end_node() -> void:
	var source_text: String = "~ start\n=> END\n"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/end_runtime.dlg"
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
	var compiled: CompiledDialogue = compile_result["compiled"]
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	var step: ConversationStep = runner.next_step()
	assert_not_null(step)
	assert_eq(step.kind, ConversationStepKind.Kind.END)
	assert_null(runner.next_step())


func test_end_step_builder_matches_runner_end_yield() -> void:
	var source_text: String = "~ start\n=> END\n"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/end_builder.dlg"
	)
	var compiled: CompiledDialogue = compile_result["compiled"]
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.END)
	assert_eq(EndStepBuilder.build(step.line_id).kind, ConversationStepKind.Kind.END)


func test_next_step_yields_wait_for_wait_command() -> void:
	var source_text: String = "~ start\n@wait 2.0\n"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/wait_runtime.dlg"
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
	var compiled: CompiledDialogue = compile_result["compiled"]
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.WAIT)
	assert_eq(step.duration_seconds, 2.0)


func test_next_step_yields_command_for_non_wait_commands() -> void:
	var source_text: String = "~ start\n@set_flag met_roll true\n"
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/command_runtime.dlg"
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
	var compiled: CompiledDialogue = compile_result["compiled"]
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	var step: ConversationStep = runner.next_step()
	assert_eq(step.kind, ConversationStepKind.Kind.COMMAND)
	assert_eq(step.command_name, "set_flag")
	assert_false(step.args_tokens.is_empty())


func test_choices_step_filters_options_by_condition() -> void:
	var source_text: String = (
		"~ start\n"
		+ "Roll: Pick one.\n"
		+ "- Always => done\n"
		+ "- Secret | if flag(\"show_secret\") => done\n"
		+ "\n"
		+ "~ done\n"
		+ "Roll: Done.\n"
	)
	var compile_result: Dictionary = DialogueCompiler.compile_string(
		source_text,
		"res://test/filtered_choices.dlg"
	)
	assert_true(compile_result["errors"].is_empty(), str(compile_result["errors"]))
	var compiled: CompiledDialogue = compile_result["compiled"]
	var context: GameContext = _mock_context()
	context.set_flag("show_secret", false)
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.set_game_context(context)
	runner.init_from_title("start")
	runner.next_step()
	var choices_step: ConversationStep = runner.next_step()
	assert_eq(choices_step.kind, ConversationStepKind.Kind.CHOICES)
	assert_eq(choices_step.options.size(), 1)
	assert_eq(choices_step.options[0]["text"], "Always")


