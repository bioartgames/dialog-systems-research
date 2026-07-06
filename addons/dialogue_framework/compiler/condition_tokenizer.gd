class_name ConditionTokenizer
extends RefCounted


const TYPE_OPERATOR := "operator"
const TYPE_CALL := "call"

const TYPE_BOOL := "bool"
const TYPE_INT := "int"
const TYPE_FLOAT := "float"
const TYPE_STRING := "string"

const ALLOWED_CALLS: PackedStringArray = ["flag", "has_item", "get_quest_state"]

const OPERATORS: PackedStringArray = [
	"==",
	"!=",
	"<=",
	">=",
	"<",
	">",
	"and",
	"or",
	"not",
]


static func tokenize(condition_text: String) -> Dictionary:
	var tokens: Array = []
	var errors: PackedStringArray = PackedStringArray()
	var remaining: String = condition_text.strip_edges()
	if remaining.is_empty():
		return {"tokens": tokens, "errors": errors}

	while not remaining.is_empty():
		remaining = remaining.strip_edges()
		if remaining.is_empty():
			break

		var consumed: Dictionary = _try_consume_call(remaining)
		if consumed.is_empty():
			consumed = _try_consume_operator(remaining)
		if consumed.is_empty():
			consumed = _try_consume_bool_literal(remaining)
		if consumed.is_empty():
			consumed = _try_consume_quoted_string(remaining)
		if consumed.is_empty():
			consumed = _try_consume_number_literal(remaining)
		if consumed.is_empty():
			errors.append("Unexpected token in condition: '%s'." % remaining.left(32))
			break

		tokens.append(consumed["token"])
		remaining = remaining.substr(int(consumed["length"]))

	if not remaining.is_empty() and errors.is_empty():
		errors.append("Unexpected trailing text in condition: '%s'." % remaining.left(32))

	return {"tokens": tokens, "errors": errors}


static func _try_consume_call(remaining: String) -> Dictionary:
	var match_result: RegExMatch = _get_call_regex().search(remaining)
	if match_result == null or match_result.get_start() != 0:
		return {}
	var function_name: String = match_result.get_string(1)
	if not ALLOWED_CALLS.has(function_name):
		return {}
	return {
		"length": match_result.get_end(),
		"token": {
			"type": TYPE_CALL,
			"function": function_name,
			"arg": match_result.get_string(2),
		},
	}


static func _try_consume_operator(remaining: String) -> Dictionary:
	for operator: String in OPERATORS:
		if not remaining.begins_with(operator):
			continue
		if operator in ["and", "or", "not"] and not _has_word_boundary_before(remaining):
			continue
		if operator in ["and", "or", "not"] and not _has_word_boundary_after(remaining, operator.length()):
			continue
		return {
			"length": operator.length(),
			"token": {"type": TYPE_OPERATOR, "value": operator},
		}
	return {}


static func _try_consume_bool_literal(remaining: String) -> Dictionary:
	if remaining.begins_with("true") and _has_word_boundary_after(remaining, 4):
		return {
			"length": 4,
			"token": {"type": TYPE_BOOL, "value": true},
		}
	if remaining.begins_with("false") and _has_word_boundary_after(remaining, 5):
		return {
			"length": 5,
			"token": {"type": TYPE_BOOL, "value": false},
		}
	return {}


static func _try_consume_quoted_string(remaining: String) -> Dictionary:
	if not remaining.begins_with("\""):
		return {}
	var end_index: int = remaining.find("\"", 1)
	if end_index < 0:
		return {}
	return {
		"length": end_index + 1,
		"token": {"type": TYPE_STRING, "value": remaining.substr(1, end_index - 1)},
	}


static func _try_consume_number_literal(remaining: String) -> Dictionary:
	var index: int = 0
	var saw_dot: bool = false
	while index < remaining.length():
		var character: String = remaining[index]
		if character == ".":
			if saw_dot:
				break
			saw_dot = true
			index += 1
			continue
		if character.is_valid_int():
			index += 1
			continue
		break
	if index == 0:
		return {}
	var number_text: String = remaining.substr(0, index)
	if number_text.ends_with("."):
		return {}
	if saw_dot:
		return {
			"length": index,
			"token": {"type": TYPE_FLOAT, "value": float(number_text)},
		}
	return {
		"length": index,
		"token": {"type": TYPE_INT, "value": int(number_text)},
	}


static func _has_word_boundary_after(text: String, length: int) -> bool:
	if length >= text.length():
		return true
	var next_character: String = text[length]
	return not _is_identifier_char(next_character)


static func _has_word_boundary_before(text: String) -> bool:
	return true


static func _is_identifier_char(character: String) -> bool:
	return character.is_valid_identifier() or character == "_"


static var _call_regex: RegEx


static func _get_call_regex() -> RegEx:
	if _call_regex == null:
		_call_regex = RegEx.new()
		_call_regex.compile("^(flag|has_item|get_quest_state)\\(\"([^\"]*)\"\\)")
	return _call_regex
