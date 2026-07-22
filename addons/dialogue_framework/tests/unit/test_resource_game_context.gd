extends GutTest


const ResourceGameContextScript := preload(
	"res://addons/dialogue_framework/integration/resource_game_context.gd"
)


func test_make_context_implements_game_context_surface() -> void:
	var data = ResourceGameContextScript.new()
	var context: GameContext = data.make_context()

	context.set_flag("met_roll", true)
	assert_eq(context.get_flag("met_roll"), true)
	assert_eq(data.flags["met_roll"], true)

	context.give_item("scrap", 2)
	assert_true(context.has_item("scrap"))
	context.remove_item("scrap", 1)
	assert_true(context.has_item("scrap"))
	assert_eq(int(data.items["scrap"]), 1)
	context.remove_item("scrap", 1)
	assert_false(context.has_item("scrap"))

	context.start_quest("intro")
	assert_eq(context.get_quest_state("intro"), "active")
	context.complete_quest("intro")
	assert_eq(context.get_quest_state("intro"), "complete")
	assert_eq(String(data.quest_states["intro"]), "complete")

	data.display_values["player_name"] = "Mega"
	assert_eq(context.get_display_value("player_name"), "Mega")
	assert_eq(context.get_display_value("missing"), "")

	data.bindings["npc_id"] = "roll"
	assert_eq(context.get_binding("npc_id"), "roll")


func test_clear_runtime_state_preserves_display_and_bindings() -> void:
	var data = ResourceGameContextScript.new()
	data.flags["x"] = true
	data.items["scrap"] = 3
	data.quest_states["intro"] = "active"
	data.display_values["hero_name"] = "Traveler"
	data.bindings["npc_id"] = "roll"

	data.clear_runtime_state()

	assert_true(data.flags.is_empty())
	assert_true(data.items.is_empty())
	assert_true(data.quest_states.is_empty())
	assert_eq(data.display_values["hero_name"], "Traveler")
	assert_eq(data.bindings["npc_id"], "roll")


func test_resource_game_context_is_resource_for_inspector() -> void:
	var data = ResourceGameContextScript.new()
	assert_true(data is Resource)
	assert_false(data is GameContext)
