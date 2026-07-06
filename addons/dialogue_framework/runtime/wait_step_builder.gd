class_name WaitStepBuilder
extends RefCounted


static func build(line_id: String, args_tokens: Array) -> ConversationStep:
	return ConversationStep.create_wait(line_id, _extract_duration(args_tokens))


static func _extract_duration(args_tokens: Array) -> float:
	if args_tokens.is_empty():
		return 0.0
	var token: Dictionary = args_tokens[0]
	match String(token.get("type", "")):
		CommandArgumentTokenizer.TYPE_FLOAT:
			return float(token.get("value", 0.0))
		CommandArgumentTokenizer.TYPE_INT:
			return float(token.get("value", 0))
		_:
			return 0.0
