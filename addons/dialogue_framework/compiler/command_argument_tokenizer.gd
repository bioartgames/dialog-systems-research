class_name CommandArgumentTokenizer
extends RefCounted


const TYPE_BOOL := "bool"
const TYPE_INT := "int"
const TYPE_FLOAT := "float"
const TYPE_STRING := "string"


static func tokenize_args(raw_args: PackedStringArray) -> Array:
	var tokens: Array = []
	for raw_arg: String in raw_args:
		tokens.append(tokenize_literal(raw_arg))
	return tokens


static func tokenize_literal(raw_value: String) -> Dictionary:
	if raw_value == "true":
		return {"type": TYPE_BOOL, "value": true}
	if raw_value == "false":
		return {"type": TYPE_BOOL, "value": false}
	if raw_value.is_valid_int():
		return {"type": TYPE_INT, "value": int(raw_value)}
	if raw_value.is_valid_float():
		return {"type": TYPE_FLOAT, "value": float(raw_value)}
	return {"type": TYPE_STRING, "value": raw_value}
