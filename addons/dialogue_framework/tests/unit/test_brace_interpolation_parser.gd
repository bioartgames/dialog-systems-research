extends GutTest


const MANIFEST_PATH := "res://addons/dialogue_framework/tests/fixtures/test_flag_manifest.tres"


func test_extracts_brace_keys_from_line_text() -> void:
	var extracted: Dictionary = BraceInterpolationParser.extract_keys("You have {scrap_count} scrap.")
	assert_eq(extracted["keys"], PackedStringArray(["scrap_count"]))
	assert_true(extracted["errors"].is_empty())


func test_rejects_inline_text_conditionals() -> void:
	var extracted: Dictionary = BraceInterpolationParser.extract_keys("Hello [if flag(\"x\")]there[/if]")
	assert_false(extracted["errors"].is_empty())


func test_validates_keys_against_flag_manifest() -> void:
	var manifest: FlagManifest = load(MANIFEST_PATH) as FlagManifest
	var errors: PackedStringArray = BraceInterpolationParser.validate_keys_against_manifest(
		PackedStringArray(["quest_done", "unknown_key"]),
		manifest
	)
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("unknown_key"))
