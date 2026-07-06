extends GutTest


func test_author_override_parsed_from_line() -> void:
	var author_id := LineIdGenerator.parse_author_override("[id:quest_intro] Roll: Welcome.")
	assert_eq(author_id, "quest_intro")


func test_fallback_line_id_format() -> void:
	var line_id := LineIdGenerator.generate_fallback("res://npcs/roll.dlg", 12)
	assert_eq(line_id, "res://npcs/roll.dlg::12")


func test_resolve_prefers_author_override() -> void:
	var line_id := LineIdGenerator.resolve_line_id(
		"[id:stable_key] Roll: Hi",
		"res://npcs/roll.dlg",
		3
	)
	assert_eq(line_id, "stable_key")


func test_translation_key_matches_line_id_resolution() -> void:
	var raw := "Roll: Hello."
	var source := "res://npcs/roll.dlg"
	assert_eq(
		LineIdGenerator.resolve_translation_key(raw, source, 5),
		LineIdGenerator.resolve_line_id(raw, source, 5)
	)
