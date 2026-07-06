extends GutTest


func test_recognizes_dlg_extension() -> void:
	assert_true(DlgLexer.is_dlg_path("res://npcs/roll.dlg"))
	assert_false(DlgLexer.is_dlg_path("res://npcs/roll.dialogue"))


func test_tokenizes_raw_lines_for_downstream_parsers() -> void:
	var source: String = "~ start\nRoll: Hello\n    - Buy => shop"
	var tokens: Array[Dictionary] = DlgLexer.tokenize(source)
	assert_eq(tokens.size(), 3)
	assert_eq(tokens[0][DlgLexer.KEY_TEXT], "~ start")
	assert_eq(tokens[0][DlgLexer.KEY_SOURCE_LINE_NUMBER], 1)
	assert_eq(tokens[1][DlgLexer.KEY_TEXT], "Roll: Hello")
	assert_eq(tokens[2][DlgLexer.KEY_INDENT_LEVEL], 1)
	assert_false(bool(tokens[2][DlgLexer.KEY_IS_EMPTY]))


func test_enforces_single_file_scope() -> void:
	var valid_source: String = "~ start\nRoll: Hello"
	assert_true(DlgLexer.validate_single_file_scope(valid_source, "res://npcs/roll.dlg"))

	var import_source: String = "import res://npcs/other.dlg\nRoll: Hi"
	var violations: PackedStringArray = DlgLexer.find_scope_violations(
		import_source,
		"res://npcs/roll.dlg"
	)
	assert_false(violations.is_empty())
	assert_true(DlgLexer.validate_single_file_scope(import_source, "res://npcs/roll.dlg") == false)
