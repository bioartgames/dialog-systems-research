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
