class_name TranslationIdentityValidator
extends RefCounted


static func is_localized_surface(line: Dictionary) -> bool:
	var kind: LineKind.Kind = CompiledLine.get_kind(line)
	return kind == LineKind.Kind.LINE or kind == LineKind.Kind.CHOICE


static func apply(
	built_lines: Array[Dictionary],
	strict: bool,
	errors: PackedStringArray,
	warnings: PackedStringArray
) -> void:
	_validate_empty_identities(built_lines, errors)
	_validate_duplicate_identities(built_lines, strict, errors, warnings)


static func validate_processor_identity_unchanged(
	identity_before: String,
	identity_after: String,
	source_line_number: int,
	errors: PackedStringArray
) -> void:
	if identity_before == identity_after:
		return
	errors.append(
		"Compile processor modified translation identity at line %d."
		% source_line_number
	)


static func _validate_empty_identities(
	built_lines: Array[Dictionary],
	errors: PackedStringArray
) -> void:
	for entry: Dictionary in built_lines:
		var line: Dictionary = entry["line"]
		if not is_localized_surface(line):
			continue
		var identity: String = String(line.get(CompiledLine.KEY_TRANSLATION_KEY, "")).strip_edges()
		if identity.is_empty():
			errors.append(
				"Empty translation identity at line %d."
				% int(line.get(CompiledLine.KEY_SOURCE_LINE_NUMBER, 0))
			)


static func _validate_duplicate_identities(
	built_lines: Array[Dictionary],
	strict: bool,
	errors: PackedStringArray,
	warnings: PackedStringArray
) -> void:
	var surfaces_by_identity: Dictionary = {}
	for entry: Dictionary in built_lines:
		var line: Dictionary = entry["line"]
		if not is_localized_surface(line):
			continue
		var identity: String = String(line.get(CompiledLine.KEY_TRANSLATION_KEY, "")).strip_edges()
		if identity.is_empty():
			continue
		if not surfaces_by_identity.has(identity):
			surfaces_by_identity[identity] = []
		(surfaces_by_identity[identity] as Array).append(
			int(line.get(CompiledLine.KEY_SOURCE_LINE_NUMBER, 0))
		)

	var identities: Array = surfaces_by_identity.keys()
	identities.sort()
	for identity: String in identities:
		var source_line_numbers: Array = surfaces_by_identity[identity]
		if source_line_numbers.size() < 2:
			continue
		source_line_numbers.sort()
		var message: String = (
			"Duplicate translation identity '%s' at lines %s."
			% [identity, _format_source_line_numbers(source_line_numbers)]
		)
		if strict:
			errors.append(message)
		else:
			warnings.append(message)


static func _format_source_line_numbers(source_line_numbers: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for line_number: Variant in source_line_numbers:
		parts.append(str(int(line_number)))
	return ", ".join(parts)
