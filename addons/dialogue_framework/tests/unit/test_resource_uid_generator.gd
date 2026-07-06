extends GutTest


func test_resolve_uses_source_path() -> void:
	assert_eq(
		ResourceUidGenerator.resolve("res://npcs/roll.dlg"),
		"res://npcs/roll.dlg"
	)


func test_resolve_empty_path_returns_empty_string() -> void:
	assert_eq(ResourceUidGenerator.resolve(""), "")
	assert_eq(ResourceUidGenerator.resolve("   "), "")
