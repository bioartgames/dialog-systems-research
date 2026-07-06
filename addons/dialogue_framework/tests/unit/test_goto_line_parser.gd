extends GutTest


func test_parses_title_and_end_goto_targets() -> void:
	var shop: Dictionary = GotoLineParser.parse("=> shop", 1)
	assert_eq(shop["target_title"], "shop")
	assert_false(bool(shop["is_end_target"]))

	var end_goto: Dictionary = GotoLineParser.parse("=> END", 2)
	assert_true(bool(end_goto["is_end_target"]))


func test_builds_goto_and_end_compiled_nodes() -> void:
	var parsed_goto: Dictionary = GotoLineParser.parse("=> shop", 3)
	var goto_line: Dictionary = GotoLineParser.build_compiled_node(
		"goto_1",
		"next_1",
		parsed_goto,
		"shop_line_id"
	)
	assert_true(CompiledLine.validate(goto_line))
	assert_eq(goto_line[CompiledLine.KEY_KIND], LineKind.Kind.GOTO)
	assert_eq(goto_line[CompiledLine.KEY_RESOLVED_TARGET_LINE_ID], "shop_line_id")

	var parsed_end: Dictionary = GotoLineParser.parse("=> END", 4)
	var end_line: Dictionary = GotoLineParser.build_compiled_node("end_1", "", parsed_end)
	assert_eq(end_line[CompiledLine.KEY_KIND], LineKind.Kind.END)


func test_does_not_match_choice_lines() -> void:
	assert_false(GotoLineParser.matches("- Leave => END"))
	assert_true(GotoLineParser.parse("- Leave => END", 5).is_empty())
