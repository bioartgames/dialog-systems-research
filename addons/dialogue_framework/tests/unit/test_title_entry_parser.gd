extends GutTest


func test_matches_and_parses_title_name() -> void:
	assert_true(TitleEntryParser.matches("~ start"))
	var parsed: Dictionary = TitleEntryParser.parse("~ start", 1)
	assert_eq(parsed["title_name"], "start")
	assert_eq(parsed["source_line_number"], 1)


func test_rejects_non_title_lines() -> void:
	assert_false(TitleEntryParser.matches("Roll: Hello"))
	assert_true(TitleEntryParser.parse("Roll: Hello", 2).is_empty())


func test_resolve_first_title_from_order() -> void:
	var names: PackedStringArray = PackedStringArray(["intro", "shop"])
	assert_eq(TitleEntryParser.resolve_first_title(names), "intro")
	assert_eq(TitleEntryParser.resolve_first_title(PackedStringArray()), "")


func test_build_title_mapping_for_start_entry() -> void:
	var entries: Array[Dictionary] = [
		TitleEntryParser.parse("~ start", 1),
		TitleEntryParser.parse("~ shop", 5),
	]
	var line_ids: PackedStringArray = PackedStringArray(["line_start", "line_shop"])
	var titles: Dictionary = TitleEntryParser.build_title_mapping(entries, line_ids)
	assert_eq(titles["start"], "line_start")
	assert_eq(titles["shop"], "line_shop")
