class_name ConditionEvaluator
extends RefCounted


static func evaluate(tokens: Array, context: GameContext) -> bool:
	if tokens.is_empty():
		return true
	if context == null:
		push_error("ConditionEvaluator requires a GameContext.")
		return false
	var index: Array[int] = [0]
	return _parse_or(tokens, index, context)


static func _parse_or(tokens: Array, index: Array[int], context: GameContext) -> bool:
	var result: bool = _parse_and(tokens, index, context)
	while index[0] < tokens.size() and _is_operator(tokens[index[0]], "or"):
		index[0] += 1
		result = result or _parse_and(tokens, index, context)
	return result


static func _parse_and(tokens: Array, index: Array[int], context: GameContext) -> bool:
	var result: bool = _parse_not(tokens, index, context)
	while index[0] < tokens.size() and _is_operator(tokens[index[0]], "and"):
		index[0] += 1
		result = result and _parse_not(tokens, index, context)
	return result


static func _parse_not(tokens: Array, index: Array[int], context: GameContext) -> bool:
	if index[0] < tokens.size() and _is_operator(tokens[index[0]], "not"):
		index[0] += 1
		return not _parse_not(tokens, index, context)
	return _parse_comparison(tokens, index, context)


static func _parse_comparison(tokens: Array, index: Array[int], context: GameContext) -> bool:
	var left: Variant = _parse_primary(tokens, index, context)
	while index[0] < tokens.size() and _is_comparison_operator(tokens[index[0]]):
		var operator: String = String(tokens[index[0]]["value"])
		index[0] += 1
		var right: Variant = _parse_primary(tokens, index, context)
		left = _apply_comparison(operator, left, right)
	return bool(left)


static func _parse_primary(tokens: Array, index: Array[int], context: GameContext) -> Variant:
	if index[0] >= tokens.size():
		push_error("ConditionEvaluator expected a value token.")
		return false
	var token: Dictionary = tokens[index[0]]
	index[0] += 1
	var token_type: String = String(token.get("type", ""))
	if token_type == ConditionTokenizer.TYPE_CALL:
		return _evaluate_call(token, context)
	if token_type == ConditionTokenizer.TYPE_BOOL:
		return bool(token.get("value", false))
	if token_type == ConditionTokenizer.TYPE_INT:
		return int(token.get("value", 0))
	if token_type == ConditionTokenizer.TYPE_FLOAT:
		return float(token.get("value", 0.0))
	if token_type == ConditionTokenizer.TYPE_STRING:
		return String(token.get("value", ""))
	push_error("ConditionEvaluator encountered unsupported token type '%s'." % token_type)
	return false


static func _evaluate_call(token: Dictionary, context: GameContext) -> Variant:
	var function_name: String = String(token.get("function", ""))
	var argument: String = String(token.get("arg", ""))
	match function_name:
		"flag":
			return context.get_flag(argument)
		"has_item":
			return context.has_item(argument)
		"get_quest_state":
			return context.get_quest_state(argument)
		_:
			push_error("ConditionEvaluator encountered unsupported call '%s'." % function_name)
			return false


static func _apply_comparison(operator: String, left: Variant, right: Variant) -> bool:
	match operator:
		"==":
			return left == right
		"!=":
			return left != right
		"<":
			return left < right
		"<=":
			return left <= right
		">":
			return left > right
		">=":
			return left >= right
		_:
			push_error("ConditionEvaluator encountered unsupported operator '%s'." % operator)
			return false


static func _is_operator(token: Dictionary, operator: String) -> bool:
	return (
		String(token.get("type", "")) == ConditionTokenizer.TYPE_OPERATOR
		and String(token.get("value", "")) == operator
	)


static func _is_comparison_operator(token: Dictionary) -> bool:
	if String(token.get("type", "")) != ConditionTokenizer.TYPE_OPERATOR:
		return false
	var operator: String = String(token.get("value", ""))
	return operator in ["==", "!=", "<", "<=", ">", ">="]
