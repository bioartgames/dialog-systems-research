extends GutTest


const MANIFEST_PATH := "res://addons/dialogue_framework/tests/fixtures/test_flag_manifest.tres"


func test_skips_flag_validation_without_manifest() -> void:
	var errors: PackedStringArray = FlagManifestValidator.validate_condition_text(
		'flag("unknown_flag")',
		null,
		1
	)
	assert_true(errors.is_empty())


func test_errors_on_unknown_flag_when_manifest_present() -> void:
	var manifest: FlagManifest = load(MANIFEST_PATH) as FlagManifest
	var errors: PackedStringArray = FlagManifestValidator.validate_condition_text(
		'flag("unknown_flag")',
		manifest,
		2
	)
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("unknown_flag"))


func test_allows_declared_flag() -> void:
	var manifest: FlagManifest = load(MANIFEST_PATH) as FlagManifest
	var errors: PackedStringArray = FlagManifestValidator.validate_condition_text(
		'flag("quest_done")',
		manifest,
		3
	)
	assert_true(errors.is_empty(), str(errors))
