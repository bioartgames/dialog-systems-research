class_name FlagManifestValidator
extends RefCounted


static func validate_condition_text(
	condition_text: String,
	flag_manifest: FlagManifest,
	source_line_number: int
) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if condition_text.strip_edges().is_empty():
		return errors

	var parsed: Dictionary = ConditionAuthorDslParser.parse_condition_source(condition_text)
	errors.append_array(parsed.get("errors", PackedStringArray()))
	if flag_manifest == null:
		return errors

	for call: Dictionary in parsed.get("calls", []):
		if String(call.get("function", "")) != "flag":
			continue
		var flag_name: String = String(call.get("argument", ""))
		if not flag_manifest.has_declared_flag(flag_name):
			errors.append("Unknown flag '%s' at line %d." % [flag_name, source_line_number])
	return errors


static func validate_brace_keys(
	keys: PackedStringArray,
	flag_manifest: FlagManifest
) -> PackedStringArray:
	return BraceInterpolationParser.validate_keys_against_manifest(keys, flag_manifest)
