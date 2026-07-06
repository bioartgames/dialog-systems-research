extends GutTest


func test_condition_evaluator_extends_refcounted_without_scene_tree() -> void:
	var script: Script = ConditionEvaluator
	assert_true(script is GDScript)
	var instance: RefCounted = script.new()
	assert_true(instance is RefCounted)
	assert_eq(instance.get_class(), "RefCounted")


func test_evaluates_flag_call() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.set_flag("met_roll", true)
	var tokens: Array = [{"type": "call", "function": "flag", "arg": "met_roll"}]
	assert_true(ConditionEvaluator.evaluate(tokens, context))


func test_evaluates_has_item_call() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.give_item("key_card", 1)
	var tokens: Array = [{"type": "call", "function": "has_item", "arg": "key_card"}]
	assert_true(ConditionEvaluator.evaluate(tokens, context))


func test_evaluates_get_quest_state_call() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.start_quest("main_01")
	var tokens: Array = ConditionTokenizer.tokenize(
		'get_quest_state("main_01") == "active"'
	)["tokens"]
	assert_true(ConditionEvaluator.evaluate(tokens, context))


func test_empty_tokens_evaluate_true() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	assert_true(ConditionEvaluator.evaluate([], context))


func test_evaluates_not_expression() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.set_flag("met_roll", false)
	var tokens: Array = ConditionTokenizer.tokenize('not flag("met_roll")')["tokens"]
	assert_true(ConditionEvaluator.evaluate(tokens, context))


func test_evaluates_and_expression() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.set_flag("quest_done", true)
	context.give_item("energy_tank", 1)
	var tokens: Array = ConditionTokenizer.tokenize(
		'flag("quest_done") and has_item("energy_tank")'
	)["tokens"]
	assert_true(ConditionEvaluator.evaluate(tokens, context))


func test_evaluates_or_expression() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.set_flag("a", false)
	context.set_flag("b", true)
	var tokens: Array = ConditionTokenizer.tokenize('flag("a") or flag("b")')["tokens"]
	assert_true(ConditionEvaluator.evaluate(tokens, context))


func test_evaluates_comparison_operators() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.set_flag("score", 10)
	var eq_tokens: Array = ConditionTokenizer.tokenize('flag("score") == 10')["tokens"]
	assert_true(ConditionEvaluator.evaluate(eq_tokens, context))
	var ne_tokens: Array = ConditionTokenizer.tokenize('flag("score") != 0')["tokens"]
	assert_true(ConditionEvaluator.evaluate(ne_tokens, context))
	var lt_tokens: Array = ConditionTokenizer.tokenize('flag("score") < 20')["tokens"]
	assert_true(ConditionEvaluator.evaluate(lt_tokens, context))
	var le_tokens: Array = ConditionTokenizer.tokenize('flag("score") <= 10')["tokens"]
	assert_true(ConditionEvaluator.evaluate(le_tokens, context))
	var gt_tokens: Array = ConditionTokenizer.tokenize('flag("score") > 5')["tokens"]
	assert_true(ConditionEvaluator.evaluate(gt_tokens, context))
	var ge_tokens: Array = ConditionTokenizer.tokenize('flag("score") >= 10')["tokens"]
	assert_true(ConditionEvaluator.evaluate(ge_tokens, context))


func test_evaluates_string_and_float_literals() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.set_flag("label", "alpha")
	var string_tokens: Array = ConditionTokenizer.tokenize('flag("label") == "alpha"')["tokens"]
	assert_true(ConditionEvaluator.evaluate(string_tokens, context))
	context.set_flag("ratio", 1.5)
	var float_tokens: Array = ConditionTokenizer.tokenize('flag("ratio") == 1.5')["tokens"]
	assert_true(ConditionEvaluator.evaluate(float_tokens, context))


func test_rejects_unsupported_call_tokens() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	var tokens: Array = [{"type": "call", "function": "evil", "arg": "x"}]
	assert_false(ConditionEvaluator.evaluate(tokens, context))
	assert_push_error("unsupported call")
