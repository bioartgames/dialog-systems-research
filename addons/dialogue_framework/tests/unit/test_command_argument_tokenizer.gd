extends GutTest


func test_tokenizes_literal_types() -> void:
	var tokens: Array = CommandArgumentTokenizer.tokenize_args(
		PackedStringArray(["true", "42", "1.5", "hello"])
	)
	assert_eq(tokens.size(), 4)
	assert_eq(tokens[0], {"type": "bool", "value": true})
	assert_eq(tokens[1], {"type": "int", "value": 42})
	assert_eq(tokens[2], {"type": "float", "value": 1.5})
	assert_eq(tokens[3], {"type": "string", "value": "hello"})


func test_tokenizes_empty_args() -> void:
	assert_eq(CommandArgumentTokenizer.tokenize_args(PackedStringArray()).size(), 0)
