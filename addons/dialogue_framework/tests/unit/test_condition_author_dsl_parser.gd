extends GutTest


func test_parses_supported_condition_calls() -> void:
	var parsed: Dictionary = ConditionAuthorDslParser.parse_condition_source(
		"flag(\"quest_done\") and has_item(\"energy_tank\")"
	)
	assert_true(bool(parsed["is_valid"]))
	assert_eq(parsed["calls"].size(), 2)
	assert_eq(parsed["calls"][0]["function"], "flag")
	assert_eq(parsed["calls"][1]["function"], "has_item")


func test_parses_get_quest_state_call() -> void:
	var parsed: Dictionary = ConditionAuthorDslParser.parse_condition_source(
		"get_quest_state(\"main_01\")"
	)
	assert_true(bool(parsed["is_valid"]))
	assert_eq(parsed["calls"][0]["function"], "get_quest_state")


func test_rejects_get_flag_call() -> void:
	var parsed: Dictionary = ConditionAuthorDslParser.parse_condition_source('get_flag("quest_done")')
	assert_false(bool(parsed["is_valid"]))
	assert_true(String(parsed["errors"][0]).contains("get_flag()"))


func test_output_includes_condition_source_for_tokenization() -> void:
	var source: String = "flag(\"met_roll\")"
	var parsed: Dictionary = ConditionAuthorDslParser.parse_condition_source(source)
	assert_eq(parsed["condition_source"], source)
	assert_false(parsed["calls"].is_empty())
