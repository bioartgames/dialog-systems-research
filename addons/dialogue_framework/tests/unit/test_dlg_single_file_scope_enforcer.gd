extends GutTest


func test_enforces_single_file_scope() -> void:
	assert_true(
		DlgSingleFileScopeEnforcer.enforce("~ start\nRoll: Hello", "res://npcs/roll.dlg")
	)


func test_rejects_cross_file_import_syntax() -> void:
	assert_false(
		DlgSingleFileScopeEnforcer.enforce(
			"import res://npcs/other.dlg\nRoll: Hi",
			"res://npcs/roll.dlg"
		)
	)
	assert_push_error("Cross-file import is not supported in v1")


func test_reports_violations_without_logging() -> void:
	var violations: PackedStringArray = DlgSingleFileScopeEnforcer.get_violations(
		"using res://npcs/other.dlg",
		"res://npcs/roll.dlg"
	)
	assert_false(violations.is_empty())
	assert_true(DlgSingleFileScopeEnforcer.has_cross_file_import_syntax(
		"using res://npcs/other.dlg",
		"res://npcs/roll.dlg"
	))
