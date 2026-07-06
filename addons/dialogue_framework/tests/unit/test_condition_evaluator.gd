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
