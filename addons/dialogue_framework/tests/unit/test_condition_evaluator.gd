extends GutTest


func test_evaluates_flag_call() -> void:
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.set_flag("met_roll", true)
	var tokens: Array = [{"type": "call", "function": "flag", "arg": "met_roll"}]
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
