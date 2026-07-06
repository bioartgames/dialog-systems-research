extends GutTest


func test_extracts_override_id_when_present() -> void:
	assert_true(LineIdOverrideParser.matches("[id:quest_intro] Roll: Welcome."))
	assert_eq(LineIdOverrideParser.parse_override_id("[id:quest_intro] Roll: Welcome."), "quest_intro")


func test_strips_override_prefix_for_downstream_parsers() -> void:
	var stripped: String = LineIdOverrideParser.strip_override_prefix("[id:intro] Roll: Hi")
	assert_eq(stripped, "Roll: Hi")


func test_integrates_with_line_id_generator() -> void:
	var line_id: String = LineIdOverrideParser.resolve_line_id(
		"[id:stable_key] Roll: Hi",
		"res://npcs/roll.dlg",
		3
	)
	assert_eq(line_id, "stable_key")
