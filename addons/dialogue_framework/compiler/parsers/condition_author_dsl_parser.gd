class_name ConditionAuthorDslParser
extends RefCounted


const ALLOWED_CALLS: PackedStringArray = ["flag", "has_item", "get_quest_state"]


static func parse_condition_source(condition_text: String) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var calls: Array[Dictionary] = []
	if condition_text.strip_edges().is_empty():
		errors.append("Condition expression is empty.")
		return _build_result(condition_text, calls, errors)

	if condition_text.contains("get_flag("):
		errors.append("get_flag() is not supported; use flag() (D8.6).")

	for match: RegExMatch in _get_call_regex().search_all(condition_text):
		var function_name: String = match.get_string(1)
		var argument: String = match.get_string(2)
		if function_name == "get_flag":
			continue
		if not ALLOWED_CALLS.has(function_name):
			errors.append("Unsupported condition call '%s'." % function_name)
			continue
		calls.append({
			"function": function_name,
			"argument": argument,
		})

	if calls.is_empty() and errors.is_empty():
		errors.append("No supported condition calls found.")

	return _build_result(condition_text, calls, errors)


static func _build_result(
	condition_text: String,
	calls: Array[Dictionary],
	errors: PackedStringArray
) -> Dictionary:
	return {
		"condition_source": condition_text,
		"calls": calls,
		"errors": errors,
		"is_valid": errors.is_empty(),
	}


static var _call_regex: RegEx


static func _get_call_regex() -> RegEx:
	if _call_regex == null:
		_call_regex = RegEx.new()
		_call_regex.compile("(flag|has_item|get_quest_state|get_flag)\\(\"([^\"]*)\"\\)")
	return _call_regex
