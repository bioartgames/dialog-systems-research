extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/test_flag_manifest.tres"


func test_loads_from_path() -> void:
	var manifest: FlagManifest = FlagManifest.load_from_path(FIXTURE_PATH)
	assert_not_null(manifest)
	assert_true(manifest.has_declared_flag("quest_done"))
	assert_true(manifest.has_declared_brace_key("player_name"))


func test_empty_path_returns_null() -> void:
	assert_null(FlagManifest.load_from_path(""))


func test_declares_flags_only_not_runtime_item_ids() -> void:
	var manifest := FlagManifest.new()
	manifest.flags = PackedStringArray(["quest_done"])
	assert_true(manifest.has_declared_flag("quest_done"))
	assert_false(manifest.has_declared_flag("scrap_piece"))
