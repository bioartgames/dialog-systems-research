class_name CommandLineParser
extends RefCounted


const COMMAND_PREFIX := "@"


static func matches(text: String) -> bool:
	return text.strip_edges().begins_with(COMMAND_PREFIX)


static func parse(text: String, source_line_number: int) -> Dictionary:
	if not matches(text):
		return {}
	var content: String = text.strip_edges()
	var body: String = content.substr(COMMAND_PREFIX.length()).strip_edges()
	if body.is_empty():
		return {}
	var space_index: int = _find_command_name_end(body)
	if space_index < 0:
		return {
			"command_name": body,
			"args": PackedStringArray(),
			"source_line_number": source_line_number,
		}
	var command_name: String = body.substr(0, space_index).strip_edges()
	var args_text: String = body.substr(space_index).strip_edges()
	if command_name.is_empty():
		return {}
	return {
		"command_name": command_name,
		"args": _tokenize_args(args_text),
		"source_line_number": source_line_number,
	}


static func supports_command_name(command_name: String) -> bool:
	return not command_name.is_empty()


static func _find_command_name_end(body: String) -> int:
	for i: int in body.length():
		if body[i] == " " or body[i] == "\t":
			return i
	return -1


static func _tokenize_args(args_text: String) -> PackedStringArray:
	var tokens: PackedStringArray = PackedStringArray()
	if args_text.is_empty():
		return tokens
	var index: int = 0
	while index < args_text.length():
		while index < args_text.length() and args_text[index] in [" ", "\t"]:
			index += 1
		if index >= args_text.length():
			break
		if args_text[index] == "\"":
			var parsed: Dictionary = _read_quoted_arg(args_text, index)
			tokens.append(parsed["value"])
			index = int(parsed["next_index"])
			continue
		var parsed_unquoted: Dictionary = _read_unquoted_arg(args_text, index)
		tokens.append(parsed_unquoted["value"])
		index = int(parsed_unquoted["next_index"])
	return tokens


static func _read_quoted_arg(args_text: String, start_index: int) -> Dictionary:
	var value: String = ""
	var index: int = start_index + 1
	while index < args_text.length():
		var character: String = args_text[index]
		if character == "\"":
			return {"value": value, "next_index": index + 1}
		value += character
		index += 1
	return {"value": value, "next_index": index}


static func _read_unquoted_arg(args_text: String, start_index: int) -> Dictionary:
	var value: String = ""
	var index: int = start_index
	while index < args_text.length() and not args_text[index] in [" ", "\t"]:
		value += args_text[index]
		index += 1
	return {"value": value, "next_index": index}
