extends GutTest


func test_parses_choice_text_and_target_title() -> void:
	var parsed: Dictionary = ChoiceLineParser.parse("- Buy items => shop", 1)
	assert_eq(parsed["text"], "Buy items")
	assert_eq(parsed["target_title"], "shop")
	assert_false(bool(parsed["is_end_target"]))


func test_parses_end_target() -> void:
	var parsed: Dictionary = ChoiceLineParser.parse("- Leave => END", 2)
	assert_true(bool(parsed["is_end_target"]))
	assert_eq(parsed["target_title"], "END")


func test_parses_optional_condition() -> void:
	var parsed: Dictionary = ChoiceLineParser.parse(
		"- Secret option | if flag(\"found_cache\") => cache_talk",
		3
	)
	assert_eq(parsed["text"], "Secret option")
	assert_eq(parsed["condition_text"], "flag(\"found_cache\")")
	assert_eq(parsed["target_title"], "cache_talk")


func test_builds_valid_compiled_choice_dict() -> void:
	var parsed: Dictionary = ChoiceLineParser.parse("- Buy items => shop", 4)
	var choice: Dictionary = ChoiceLineParser.build_choice_line("choice_1", "next_1", parsed, "shop_line")
	assert_true(CompiledLine.validate(choice))
	assert_eq(choice[CompiledLine.KEY_TEXT], "Buy items")
	assert_eq(choice[CompiledLine.KEY_TARGET_LINE_ID], "shop_line")


func test_rejects_non_choice_lines() -> void:
	assert_false(ChoiceLineParser.matches("Roll: Hello"))
	assert_true(ChoiceLineParser.parse("Roll: Hello", 5).is_empty())
