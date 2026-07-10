extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/branching_exit.dlg"
const FIXTURE_PREFIX := "res://addons/dialogue_framework/tests/fixtures/branching_exit.dlg"


func _compile_fixture() -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func _line_by_text(compiled: CompiledDialogue, text: String) -> Dictionary:
	for line_id: String in compiled.lines:
		var line: Dictionary = compiled.lines[line_id]
		if line.get(CompiledLine.KEY_TEXT, "") == text:
			return line
	push_error("Line not found: %s" % text)
	return {}


func _first_choice_line_id(compiled: CompiledDialogue) -> String:
	for line_id: String in compiled.lines:
		var line: Dictionary = compiled.lines[line_id]
		if CompiledLine.get_kind(line) == LineKind.Kind.CHOICE:
			return line_id
	return ""


func test_wires_true_branch_last_line_to_continuation() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var first_choice_id: String = _first_choice_line_id(compiled)
	var true_last: Dictionary = _line_by_text(compiled, "True line two.")
	assert_eq(String(true_last.get(CompiledLine.KEY_NEXT_ID, "")), first_choice_id)
	var elif_line_id: String = ""
	var else_line_id: String = ""
	for line_id: String in compiled.lines:
		var line: Dictionary = compiled.lines[line_id]
		match String(line.get(CompiledLine.KEY_TEXT, "")):
			"Elif line.":
				elif_line_id = line_id
			"Else line.":
				else_line_id = line_id
	assert_ne(String(true_last.get(CompiledLine.KEY_NEXT_ID, "")), elif_line_id)
	assert_ne(String(true_last.get(CompiledLine.KEY_NEXT_ID, "")), else_line_id)


func test_wires_all_condition_headers_next_id_after() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var first_choice_id: String = _first_choice_line_id(compiled)
	for line_id: String in compiled.lines:
		var line: Dictionary = compiled.lines[line_id]
		if CompiledLine.get_kind(line) != LineKind.Kind.CONDITION:
			continue
		assert_eq(
			String(line.get(CompiledLine.KEY_NEXT_ID_AFTER, "")),
			first_choice_id,
			"Condition header %s should exit to first choice." % line_id
		)


func test_multi_line_body_intermediate_unchanged() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var true_first: Dictionary = _line_by_text(compiled, "True line one.")
	var true_second: Dictionary = _line_by_text(compiled, "True line two.")
	var true_first_id: String = ""
	for line_id: String in compiled.lines:
		if compiled.lines[line_id] == true_first:
			true_first_id = line_id
			break
	var true_second_id: String = ""
	for line_id: String in compiled.lines:
		if compiled.lines[line_id] == true_second:
			true_second_id = line_id
			break
	assert_eq(String(true_first.get(CompiledLine.KEY_NEXT_ID, "")), true_second_id)


func test_elif_exit_skips_else_body() -> void:
	var compiled: CompiledDialogue = _compile_fixture()
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
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
