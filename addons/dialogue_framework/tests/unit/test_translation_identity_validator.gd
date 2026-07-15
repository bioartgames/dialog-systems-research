extends GutTest


func _built_line_entry(
	source_line_number: int,
	kind: LineKind.Kind,
	translation_key: String,
	text: String = "Sample text."
) -> Dictionary:
	var line: Dictionary
	match kind:
		LineKind.Kind.LINE:
			line = CompiledLine.create_line(
				"line_%d" % source_line_number,
				source_line_number,
				"",
				"Roll",
				text,
				PackedStringArray(),
				translation_key
			)
		LineKind.Kind.CHOICE:
			line = CompiledLine.create_choice(
				"choice_%d" % source_line_number,
				source_line_number,
				"",
				text,
				[],
				"target",
				translation_key
			)
		_:
			assert_true(false, "Unsupported kind for fixture")
			line = {}
	return {"id": String(line.get(CompiledLine.KEY_ID, "")), "line": line}


func test_empty_translation_identity_errors_for_line_and_choice() -> void:
	var built_lines: Array[Dictionary] = [
		_built_line_entry(2, LineKind.Kind.LINE, ""),
		_built_line_entry(4, LineKind.Kind.CHOICE, "", "Leave"),
	]
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	TranslationIdentityValidator.apply(built_lines, false, errors, warnings)
	assert_eq(errors.size(), 2)
	assert_true(errors[0].contains("Empty translation identity"))
	assert_true(errors[1].contains("Empty translation identity"))


func test_duplicate_translation_identity_warns_on_local_compile() -> void:
	var built_lines: Array[Dictionary] = [
		_built_line_entry(2, LineKind.Kind.LINE, "dup_key", "A."),
		_built_line_entry(3, LineKind.Kind.LINE, "dup_key", "B."),
	]
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	TranslationIdentityValidator.apply(built_lines, false, errors, warnings)
	assert_true(errors.is_empty())
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("Duplicate translation identity 'dup_key'"))


func test_duplicate_translation_identity_errors_on_strict_compile() -> void:
	var built_lines: Array[Dictionary] = [
		_built_line_entry(2, LineKind.Kind.CHOICE, "dup_choice", "One"),
		_built_line_entry(3, LineKind.Kind.CHOICE, "dup_choice", "Two"),
	]
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	TranslationIdentityValidator.apply(built_lines, true, errors, warnings)
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("Duplicate translation identity 'dup_choice'"))
	assert_true(warnings.is_empty())


func test_processor_identity_mutation_is_reported() -> void:
	var errors: PackedStringArray = PackedStringArray()
	TranslationIdentityValidator.validate_processor_identity_unchanged(
		"stable_key",
		"mutated_key",
		7,
		errors
	)
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("Compile processor modified translation identity"))


func test_is_localized_surface_includes_line_and_choice_only() -> void:
	var line: Dictionary = CompiledLine.create_line(
		"l1", 1, "", "Roll", "Hi.", PackedStringArray(), "key"
	)
	var choice: Dictionary = CompiledLine.create_choice(
		"c1", 2, "", "Leave", [], "end", "choice_key"
	)
	var command: Dictionary = CompiledLine.create_command("cmd1", 3, "", "set_flag", [])
	assert_true(TranslationIdentityValidator.is_localized_surface(line))
	assert_true(TranslationIdentityValidator.is_localized_surface(choice))
	assert_false(TranslationIdentityValidator.is_localized_surface(command))
