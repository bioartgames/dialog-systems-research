extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func test_builds_compiled_lines_with_source_line_numbers() -> void:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		FIXTURE_PATH
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	assert_false(result["lines"].is_empty())
	for line_id: String in result["lines"]:
		var line: Dictionary = result["lines"][line_id]
		assert_true(line.has(CompiledLine.KEY_SOURCE_LINE_NUMBER))
		assert_true(CompiledLine.validate(line))


func test_creates_title_line_choice_and_end_nodes() -> void:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = FlatGraphBuilder.build(source_text, FIXTURE_PATH)
	var kinds: Array[int] = []
	for line_id: String in result["lines"]:
		kinds.append(int(result["lines"][line_id][CompiledLine.KEY_KIND]))
	assert_true(kinds.has(LineKind.Kind.TITLE))
	assert_true(kinds.has(LineKind.Kind.LINE))
	assert_true(kinds.has(LineKind.Kind.CHOICE))


func test_command_nodes_store_pre_tokenized_args() -> void:
	var source_text: String = "@wait 1.5\n@set_flag met_roll true"
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		"res://test/commands.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var command_lines: Array[Dictionary] = []
	for line_id: String in result["lines"]:
		var line: Dictionary = result["lines"][line_id]
		if CompiledLine.get_kind(line) == LineKind.Kind.COMMAND:
			command_lines.append(line)
	assert_eq(command_lines.size(), 2)
	assert_eq(command_lines[0][CompiledLine.KEY_ARGS_TOKENS][0], {"type": "float", "value": 1.5})
	assert_eq(command_lines[1][CompiledLine.KEY_ARGS_TOKENS][0], {"type": "string", "value": "met_roll"})
	assert_eq(command_lines[1][CompiledLine.KEY_ARGS_TOKENS][1], {"type": "bool", "value": true})


func test_choice_block_shares_next_id_after_group() -> void:
	var source_text: String = (
		"~ start\n"
		+ "Roll: Pick one.\n"
		+ "- Option A => END\n"
		+ "- Option B => END\n"
		+ "Roll: After choices.\n"
	)
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		"res://test/choices.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var choice_lines: Array[Dictionary] = []
	var after_choice_line: Dictionary = {}
	for line_id: String in result["lines"]:
		var line: Dictionary = result["lines"][line_id]
		if CompiledLine.get_kind(line) == LineKind.Kind.CHOICE:
			choice_lines.append(line)
		elif line.get(CompiledLine.KEY_TEXT) == "After choices.":
			after_choice_line = line
	assert_eq(choice_lines.size(), 2)
	var shared_next_id: String = String(choice_lines[0][CompiledLine.KEY_NEXT_ID])
	assert_eq(shared_next_id, String(choice_lines[1][CompiledLine.KEY_NEXT_ID]))
	assert_eq(shared_next_id, String(after_choice_line[CompiledLine.KEY_ID]))


func test_resolves_valid_goto_target_at_compile_time() -> void:
	var source_text: String = (
		"~ start\n"
		+ "Roll: Hi.\n"
		+ "=> shop\n"
		+ "\n"
		+ "~ shop\n"
		+ "Roll: Welcome.\n"
	)
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		"res://test/goto.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var goto_line: Dictionary = {}
	for line_id: String in result["lines"]:
		var line: Dictionary = result["lines"][line_id]
		if CompiledLine.get_kind(line) == LineKind.Kind.GOTO:
			goto_line = line
	assert_false(goto_line.is_empty())
	assert_eq(
		goto_line[CompiledLine.KEY_RESOLVED_TARGET_LINE_ID],
		result["titles"]["shop"]
	)


func test_invalid_goto_target_fails_compile() -> void:
	var source_text: String = "~ start\n=> missing_title\n"
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		"res://test/bad_goto.dlg"
	)
	assert_false(result["errors"].is_empty())
	assert_true(String(result["errors"][0]).contains("missing_title"))


func test_unknown_flag_errors_when_manifest_present() -> void:
	var manifest: FlagManifest = load(
		"res://addons/dialogue_framework/tests/fixtures/test_flag_manifest.tres"
	) as FlagManifest
	var source_text: String = FileAccess.get_file_as_string(
		"res://addons/dialogue_framework/tests/fixtures/branching.dlg"
	)
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		"res://addons/dialogue_framework/tests/fixtures/branching.dlg",
		manifest
	)
	assert_false(result["errors"].is_empty())
	assert_true(String(result["errors"][0]).contains("met_roll"))


func test_branch_exit_wires_true_body_past_else_body() -> void:
	var source_text: String = FileAccess.get_file_as_string(
		"res://addons/dialogue_framework/tests/fixtures/branching_exit.dlg"
	)
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		"res://addons/dialogue_framework/tests/fixtures/branching_exit.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var true_last: Dictionary = {}
	var elif_line: Dictionary = {}
	var first_choice_id: String = ""
	for line_id: String in result["lines"]:
		var line: Dictionary = result["lines"][line_id]
		match String(line.get(CompiledLine.KEY_TEXT, "")):
			"True line two.":
				true_last = line
			"Elif line.":
				elif_line = line
			"After branch A":
				first_choice_id = line_id
	assert_false(true_last.is_empty())
	assert_false(elif_line.is_empty())
	assert_false(first_choice_id.is_empty())
	assert_eq(String(true_last.get(CompiledLine.KEY_NEXT_ID, "")), first_choice_id)
	assert_ne(String(true_last.get(CompiledLine.KEY_NEXT_ID, "")), String(elif_line.get(CompiledLine.KEY_ID, "")))
