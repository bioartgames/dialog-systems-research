extends GutTest


const MockGameContext := preload("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd")


func test_mock_game_context_implements_required_methods() -> void:
	var context: GameContext = MockGameContext.new()
	context.set_flag("met_roll", true)
	assert_eq(context.get_flag("met_roll"), true)
	context.give_item("scrap", 2)
	assert_true(context.has_item("scrap"))
	context.remove_item("scrap", 1)
	assert_true(context.has_item("scrap"))
	context.start_quest("intro")
	assert_eq(context.get_quest_state("intro"), "active")
	context.complete_quest("intro")
	assert_eq(context.get_quest_state("intro"), "complete")
	context.display_values["player_name"] = "Mega"
	assert_eq(context.get_display_value("player_name"), "Mega")
	context.bindings["npc_id"] = "roll"
	assert_eq(context.get_binding("npc_id"), "roll")
