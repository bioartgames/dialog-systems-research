extends RefCounted


const GOLDEN_DIR := "res://addons/dialogue_framework/tests/golden/"


static func serialize_compiled(compiled: CompiledDialogue) -> Dictionary:
	var lines: Dictionary = {}
	var line_ids: Array = compiled.lines.keys()
	line_ids.sort()
	for line_id: String in line_ids:
		lines[line_id] = _normalize_value(compiled.lines[line_id])
	var titles: Dictionary = {}
	var title_keys: Array = compiled.titles.keys()
	title_keys.sort()
	for title_key: String in title_keys:
		titles[title_key] = compiled.titles[title_key]
	return {
		"compiler_version": compiled.compiler_version,
		"format_version": compiled.format_version,
		"first_title": compiled.first_title,
		"resource_uid": compiled.resource_uid,
		"source_path": compiled.source_path,
		"titles": titles,
		"lines": lines,
	}


static func golden_path_for(fixture_path: String) -> String:
	var base_name: String = fixture_path.get_file().get_basename()
	return GOLDEN_DIR + base_name + ".compile.json"


static func load_golden(fixture_path: String) -> Dictionary:
	var golden_path: String = golden_path_for(fixture_path)
	var text: String = FileAccess.get_file_as_string(golden_path)
	var parsed: Variant = JSON.parse_string(text)
	return _normalize_value(parsed) as Dictionary


static func compare(actual: Dictionary, expected: Dictionary) -> String:
	var actual_json: String = JSON.stringify(actual, "\t")
	var expected_json: String = JSON.stringify(expected, "\t")
	if actual_json == expected_json:
		return ""
	return (
		"Golden snapshot mismatch for compiler output.\n"
		+ "Expected:\n%s\n\nActual:\n%s"
		% [expected_json, actual_json]
	)


static func _normalize_value(value: Variant) -> Variant:
	if value is Dictionary:
		var normalized: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort()
		for key: Variant in keys:
			normalized[String(key)] = _normalize_value(value[key])
		return normalized
	if value is PackedStringArray:
		var array: Array = []
		for item: String in value:
			array.append(item)
		return array
	if value is Array:
		var normalized_array: Array = []
		for item: Variant in value:
			normalized_array.append(_normalize_value(item))
		return normalized_array
	if value is float:
		var as_int: int = int(value)
		if float(as_int) == value:
			return as_int
	return value
