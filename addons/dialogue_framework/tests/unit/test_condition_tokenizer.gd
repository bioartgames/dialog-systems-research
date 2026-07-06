extends GutTest


func test_tokenizes_calls_operators_and_literals() -> void:
	var result: Dictionary = ConditionTokenizer.tokenize(
		'flag("quest_done") and has_item("energy_tank") == true'
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var tokens: Array = result["tokens"]
	assert_eq(tokens.size(), 5)
	assert_eq(tokens[0], {"type": "call", "function": "flag", "arg": "quest_done"})
	assert_eq(tokens[1], {"type": "operator", "value": "and"})
	assert_eq(tokens[2], {"type": "call", "function": "has_item", "arg": "energy_tank"})
	assert_eq(tokens[3], {"type": "operator", "value": "=="})
	assert_eq(tokens[4], {"type": "bool", "value": true})


func test_tokenizes_numeric_and_comparison_operators() -> void:
	var result: Dictionary = ConditionTokenizer.tokenize("3 <= 5 and not flag(\"x\")")
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var tokens: Array = result["tokens"]
	assert_eq(tokens[0], {"type": "int", "value": 3})
	assert_eq(tokens[1], {"type": "operator", "value": "<="})
	assert_eq(tokens[2], {"type": "int", "value": 5})
	assert_eq(tokens[3], {"type": "operator", "value": "and"})
	assert_eq(tokens[4], {"type": "operator", "value": "not"})
	assert_eq(tokens[5], {"type": "call", "function": "flag", "arg": "x"})


func test_tokenizes_get_quest_state_call() -> void:
	var result: Dictionary = ConditionTokenizer.tokenize('get_quest_state("main_01")')
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	assert_eq(result["tokens"].size(), 1)
	assert_eq(result["tokens"][0]["function"], "get_quest_state")


func test_returns_empty_tokens_for_empty_condition() -> void:
	var result: Dictionary = ConditionTokenizer.tokenize("   ")
	assert_true(result["errors"].is_empty())
	assert_eq(result["tokens"].size(), 0)


func test_errors_on_unsupported_syntax() -> void:
	var result: Dictionary = ConditionTokenizer.tokenize('get_flag("quest_done")')
	assert_false(result["errors"].is_empty())
