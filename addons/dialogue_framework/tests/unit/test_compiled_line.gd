extends GutTest


func test_shared_fields_present_on_all_kinds() -> void:
	var line := CompiledLine.create_line("id", 1, "next", "Roll", "Hi")
	for key: StringName in CompiledLine.SHARED_KEYS:
		assert_true(line.has(key), "Missing shared key %s" % key)


func test_kind_specific_fields_per_schema() -> void:
	var title := CompiledLine.create_title("t1", 1, "n1", "start")
	assert_true(CompiledLine.validate(title))

	var dialogue_line := CompiledLine.create_line("l1", 2, "n2", "Roll", "Hello")
	assert_true(CompiledLine.validate(dialogue_line))

	var condition := CompiledLine.create_condition("c1", 3, "n3", [], "sib", "after")
	assert_true(CompiledLine.validate(condition))

	var choice := CompiledLine.create_choice("ch1", 4, "n4", "Yes", [], "target")
	assert_true(CompiledLine.validate(choice))

	var command := CompiledLine.create_command("cmd1", 5, "n5", "wait", ["1.0"])
	assert_true(CompiledLine.validate(command))

	var goto_line := CompiledLine.create_goto("g1", 6, "n6", "target_id")
	assert_true(CompiledLine.validate(goto_line))

	var end_line := CompiledLine.create_end("e1", 7)
	assert_true(CompiledLine.validate(end_line))


func test_line_defaults_translation_key_to_text() -> void:
	var line := CompiledLine.create_line("l1", 1, "", "Roll", "Hello there")
	assert_eq(line[CompiledLine.KEY_TRANSLATION_KEY], "Hello there")


func test_rejects_editor_metadata_fields() -> void:
	var line := CompiledLine.create_line("l1", 1, "", "Roll", "Hi")
	line["editor_note"] = "should not be allowed"
	assert_false(CompiledLine.validate(line))
	assert_push_error("unexpected field")
