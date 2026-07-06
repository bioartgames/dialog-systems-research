class_name ShowcaseGameContext
extends GameContext

const HERO_NAME_KEY: String = "hero_name"
const SHOWCASE_FLAG_DISPLAY_KEY: String = "showcase_flag_display"


var flags: Dictionary = {}
var items: Dictionary = {}
var quest_states: Dictionary = {}
var display_values: Dictionary = {}
var bindings: Dictionary = {}


func _init() -> void:
	display_values[HERO_NAME_KEY] = "Traveler"
	_sync_showcase_flag_display()


func get_flag(name: String) -> Variant:
	return flags.get(name)


func set_flag(name: String, value: Variant) -> void:
	flags[name] = value
	if name == "showcase_flag":
		_sync_showcase_flag_display()


func has_item(item_id: String) -> bool:
	return int(items.get(item_id, 0)) > 0


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
	if key == SHOWCASE_FLAG_DISPLAY_KEY:
		return "true" if bool(flags.get("showcase_flag", false)) else "false"
	return String(display_values.get(key, ""))


func get_binding(key: String) -> Variant:
	return bindings.get(key)


func reset_for_showcase() -> void:
	flags.clear()
	items.clear()
	quest_states.clear()
	display_values[HERO_NAME_KEY] = "Traveler"
	_sync_showcase_flag_display()


func _sync_showcase_flag_display() -> void:
	display_values[SHOWCASE_FLAG_DISPLAY_KEY] = get_display_value(SHOWCASE_FLAG_DISPLAY_KEY)
