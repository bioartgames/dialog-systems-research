class_name BraceInterpolationParser
extends RefCounted


static var _brace_key_regex: RegEx
static var _inline_if_bracket_regex: RegEx
static var _inline_if_brace_regex: RegEx


static func extract_keys(text: String) -> Dictionary:
	var keys: PackedStringArray = PackedStringArray()
	var errors: PackedStringArray = _find_inline_conditional_errors(text)
	for match: RegExMatch in _get_brace_key_regex().search_all(text):
		var key: String = match.get_string(1)
		if not keys.has(key):
			keys.append(key)
	return {
		"keys": keys,
		"errors": errors,
	}


static func validate_keys_against_manifest(
	keys: PackedStringArray,
	manifest: FlagManifest
) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if manifest == null:
		return errors
	for key: String in keys:
		if not manifest.has_declared_brace_key(key):
			errors.append("Unknown brace interpolation key '%s'." % key)
	return errors


static func _find_inline_conditional_errors(text: String) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if _get_inline_if_bracket_regex().search(text) != null:
		errors.append("Inline text conditionals are not supported in v1 (D8.4).")
	if _get_inline_if_brace_regex().search(text) != null:
		errors.append("Inline text conditionals are not supported in v1 (D8.4).")
	return errors


static func _get_brace_key_regex() -> RegEx:
	if _brace_key_regex == null:
		_brace_key_regex = RegEx.new()
		_brace_key_regex.compile("\\{([A-Za-z_][A-Za-z0-9_]*)\\}")
	return _brace_key_regex


static func _get_inline_if_bracket_regex() -> RegEx:
	if _inline_if_bracket_regex == null:
		_inline_if_bracket_regex = RegEx.new()
		_inline_if_bracket_regex.compile("\\[if\\s")
	return _inline_if_bracket_regex


static func _get_inline_if_brace_regex() -> RegEx:
	if _inline_if_brace_regex == null:
		_inline_if_brace_regex = RegEx.new()
		_inline_if_brace_regex.compile("\\{if\\s")
	return _inline_if_brace_regex
