extends GameContext


var flags: Dictionary = {}
var items: Dictionary = {}
var quest_states: Dictionary = {}
var display_values: Dictionary = {}
var bindings: Dictionary = {}


func get_flag(name: String) -> Variant:
	return flags.get(name)


func set_flag(name: String, value: Variant) -> void:
	flags[name] = value


func has_item(item_id: String) -> bool:
	return items.get(item_id, 0) > 0


func give_item(item_id: String, count: int = 1) -> void:
	items[item_id] = int(items.get(item_id, 0)) + count


func remove_item(item_id: String, count: int = 1) -> void:
	items[item_id] = maxi(int(items.get(item_id, 0)) - count, 0)


func get_quest_state(quest_id: String) -> String:
	return String(quest_states.get(quest_id, ""))


func start_quest(quest_id: String) -> void:
	quest_states[quest_id] = "active"


func complete_quest(quest_id: String) -> void:
	quest_states[quest_id] = "complete"


func get_display_value(key: String) -> String:
	return String(display_values.get(key, ""))


func get_binding(key: String) -> Variant:
	return bindings.get(key)
