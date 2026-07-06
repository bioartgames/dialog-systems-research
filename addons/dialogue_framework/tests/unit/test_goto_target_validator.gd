extends GutTest


func test_resolves_title_target_to_line_id() -> void:
	var titles: Dictionary = {"shop": "shop_line"}
	var built_lines: Array[Dictionary] = [
		{
			"id": "goto_1",
			"line": CompiledLine.create_goto("goto_1", 3, "", "shop"),
		},
	]
	var errors: PackedStringArray = PackedStringArray()
	GotoTargetValidator.apply(built_lines, titles, errors)
	assert_true(errors.is_empty(), str(errors))
	assert_eq(
		built_lines[0]["line"][CompiledLine.KEY_RESOLVED_TARGET_LINE_ID],
		"shop_line"
	)


func test_rejects_unknown_goto_target() -> void:
	var built_lines: Array[Dictionary] = [
		{
			"id": "goto_1",
			"line": CompiledLine.create_goto("goto_1", 2, "", "missing"),
		},
	]
	var errors: PackedStringArray = PackedStringArray()
	GotoTargetValidator.apply(built_lines, {}, errors)
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("missing"))


func test_resolves_choice_title_target() -> void:
	var titles: Dictionary = {"cache_talk": "cache_line"}
	var built_lines: Array[Dictionary] = [
		{
			"id": "choice_1",
			"line": CompiledLine.create_choice("choice_1", 4, "", "Go", [], "cache_talk"),
		},
	]
	var errors: PackedStringArray = PackedStringArray()
	GotoTargetValidator.apply(built_lines, titles, errors)
	assert_true(errors.is_empty(), str(errors))
	assert_eq(built_lines[0]["line"][CompiledLine.KEY_TARGET_LINE_ID], "cache_line")
