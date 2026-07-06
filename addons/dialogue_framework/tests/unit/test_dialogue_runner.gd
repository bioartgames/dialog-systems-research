extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func _compile_fixture() -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func test_load_and_init_from_title_position_cursor() -> void:
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


func test_next_step_returns_null_in_skeleton() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var runner := DialogueRunner.new()
	runner.load(compiled)
	runner.init_from_title("start")
	assert_null(runner.next_step())
