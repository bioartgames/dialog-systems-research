extends GutTest


func test_extracts_supported_tags_from_dialogue_text() -> void:
	var extracted: Dictionary = TagParser.extract_tags("Hello there #voice=audio/roll.ogg #time=auto")
	assert_eq(extracted["text"], "Hello there")
	assert_eq(extracted["tags"], PackedStringArray(["voice=audio/roll.ogg", "time=auto"]))
	assert_true(extracted["errors"].is_empty())


func test_supports_time_numeric_tag() -> void:
	var extracted: Dictionary = TagParser.extract_tags("Wait up #time=1.5")
	assert_eq(extracted["tags"], PackedStringArray(["time=1.5"]))


func test_rejects_portrait_tag() -> void:
	var extracted: Dictionary = TagParser.extract_tags("Hello #portrait=roll")
	assert_true(extracted["tags"].is_empty())
	assert_false(extracted["errors"].is_empty())


func test_build_line_with_tags_stores_tags_on_line_node() -> void:
	var line: Dictionary = TagParser.build_line_with_tags(
		"line_1",
		"next_1",
		"Roll",
		"Need anything? #voice=audio/roll.ogg",
		2
	)
	assert_true(CompiledLine.validate(line))
	assert_eq(line[CompiledLine.KEY_TEXT], "Need anything?")
	assert_eq(line[CompiledLine.KEY_TAGS], PackedStringArray(["voice=audio/roll.ogg"]))
