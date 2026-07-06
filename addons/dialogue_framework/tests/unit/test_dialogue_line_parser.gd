extends GutTest


func test_parses_speaker_id_and_text() -> void:
	var parsed: Dictionary = DialogueLineParser.parse("Roll: Hello there.", 3)
	assert_eq(parsed["speaker_id"], "Roll")
	assert_eq(parsed["text"], "Hello there.")
	assert_eq(parsed["source_line_number"], 3)


func test_preserves_colons_in_dialogue_text() -> void:
	var parsed: Dictionary = DialogueLineParser.parse("Roll: Hello: world", 4)
	assert_eq(parsed["speaker_id"], "Roll")
	assert_eq(parsed["text"], "Hello: world")


func test_strips_id_override_before_parsing() -> void:
	var parsed: Dictionary = DialogueLineParser.parse("[id:quest_intro] Roll: Welcome back.", 2)
	assert_eq(parsed["speaker_id"], "Roll")
	assert_eq(parsed["text"], "Welcome back.")


func test_rejects_non_dialogue_lines() -> void:
	assert_false(DialogueLineParser.matches("~ start"))
	assert_false(DialogueLineParser.matches("- Buy items => shop"))
	assert_false(DialogueLineParser.matches("@wait 1.0"))
	assert_false(DialogueLineParser.matches("if flag(\"x\"):"))
	assert_true(DialogueLineParser.parse("~ start", 1).is_empty())
