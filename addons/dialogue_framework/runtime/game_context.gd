@abstract
class_name GameContext
extends RefCounted


@abstract func get_flag(name: String) -> Variant


@abstract func set_flag(name: String, value: Variant) -> void


@abstract func has_item(item_id: String) -> bool


@abstract func give_item(item_id: String, count: int = 1) -> void


@abstract func remove_item(item_id: String, count: int = 1) -> void


@abstract func get_quest_state(quest_id: String) -> String


@abstract func start_quest(quest_id: String) -> void


@abstract func complete_quest(quest_id: String) -> void


@abstract func get_display_value(key: String) -> String


@abstract func get_binding(key: String) -> Variant
