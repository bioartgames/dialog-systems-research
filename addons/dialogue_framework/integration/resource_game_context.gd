class_name ResourceGameContext
extends Resource

## Inspector-authored maps for a reference GameContext (ADR-024 / IK-1).
## This Resource is configuration and runtime scratch state for dialogue integration —
## it is NOT the authoritative game save (ADR-001 D1.1). Persist flags/items/quests
## through the game's own save system; use this Resource for demo, prototyping, or
## as a bridge that a custom GameContext can replace.


## Flag name → [Variant] values read/written by [method GameContext.get_flag] / [method GameContext.set_flag].
## Scratch / config only — not authoritative save data (ADR-001 D1.1).
@export var flags: Dictionary = {}
## Item id → [code]int[/code] count. [method GameContext.has_item] treats count greater than [code]0[/code] as owned.
## Scratch / config only — not authoritative save data (ADR-001 D1.1).
@export var items: Dictionary = {}
## Quest id → string state (e.g. [code]active[/code] / [code]complete[/code] via bridge commands).
## Scratch / config only — not authoritative save data (ADR-001 D1.1).
@export var quest_states: Dictionary = {}
## Display key → string for [code]{key}[/code] brace interpolation via [method GameContext.get_display_value].
@export var display_values: Dictionary = {}
## Opaque key → [Variant] for [method GameContext.get_binding] (game-defined bindings).
@export var bindings: Dictionary = {}


## Returns a GameContext bound to this Resource's dictionaries.
## Mutations (set_flag, give_item, …) write through to this Resource.
func make_context() -> GameContext:
	return Context.new(self)


## Clears mutable gameplay maps. Does not remove Inspector defaults you re-assign
## after clear — call sites should re-seed display_values/bindings if needed.
func clear_runtime_state() -> void:
	flags.clear()
	items.clear()
	quest_states.clear()


class Context extends GameContext:
	var _data: ResourceGameContext


	func _init(data: ResourceGameContext = null) -> void:
		_data = data


	func get_flag(name: String) -> Variant:
		return _data.flags.get(name)


	func set_flag(name: String, value: Variant) -> void:
		_data.flags[name] = value


	func has_item(item_id: String) -> bool:
		return int(_data.items.get(item_id, 0)) > 0


	func give_item(item_id: String, count: int = 1) -> void:
		_data.items[item_id] = int(_data.items.get(item_id, 0)) + count


	func remove_item(item_id: String, count: int = 1) -> void:
		_data.items[item_id] = maxi(int(_data.items.get(item_id, 0)) - count, 0)


	func get_quest_state(quest_id: String) -> String:
		return String(_data.quest_states.get(quest_id, ""))


	func start_quest(quest_id: String) -> void:
		_data.quest_states[quest_id] = "active"


	func complete_quest(quest_id: String) -> void:
		_data.quest_states[quest_id] = "complete"


	func get_display_value(key: String) -> String:
		return String(_data.display_values.get(key, ""))


	func get_binding(key: String) -> Variant:
		return _data.bindings.get(key)
