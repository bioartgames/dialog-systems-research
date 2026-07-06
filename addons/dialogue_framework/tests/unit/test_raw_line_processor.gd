extends GutTest


func test_processes_normalized_lines_with_content_and_line_id() -> void:
	var source: String = "~ start\nRoll: Hello"
	var result: Dictionary = RawLineProcessor.process(source, "res://npcs/roll.dlg")
	assert_true(result["errors"].is_empty())
	var lines: Array = result["normalized_lines"]
	assert_eq(lines.size(), 2)
	assert_eq(lines[0][RawLineProcessor.KEY_CONTENT], "~ start")
	assert_false(String(lines[0][RawLineProcessor.KEY_LINE_ID]).is_empty())


func test_preserves_source_text_and_path_for_downstream_stages() -> void:
	var source: String = "Roll: Hi"
	var path: String = "res://npcs/roll.dlg"
	var result: Dictionary = RawLineProcessor.process(source, path)
	assert_eq(result["source_text"], source)
	assert_eq(result["source_path"], path)
