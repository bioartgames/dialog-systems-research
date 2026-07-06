extends GutTest


func test_parses_if_elif_else_headers_with_indent() -> void:
	var if_header: Dictionary = BranchingParser.parse_header("if flag(\"met_roll\"):", 1)
	assert_eq(if_header["branch_kind"], BranchingParser.BranchKind.IF)
	assert_eq(if_header["condition_text"], "flag(\"met_roll\")")
	assert_eq(if_header["indent_level"], 0)

	var elif_header: Dictionary = BranchingParser.parse_header("    elif has_item(\"key\"):", 2)
	assert_eq(elif_header["branch_kind"], BranchingParser.BranchKind.ELIF)
	assert_eq(elif_header["indent_level"], 1)

	var else_header: Dictionary = BranchingParser.parse_header("else:", 3)
	assert_eq(else_header["branch_kind"], BranchingParser.BranchKind.ELSE)
	assert_eq(else_header["condition_text"], "")


func test_builds_condition_nodes_with_sibling_chain() -> void:
	var headers: Array[Dictionary] = [
		BranchingParser.parse_header("if flag(\"a\"):", 1),
		BranchingParser.parse_header("elif flag(\"b\"):", 2),
		BranchingParser.parse_header("else:", 3),
	]
	var line_ids: PackedStringArray = PackedStringArray(["c_if", "c_elif", "c_else"])
	var nodes: Array[Dictionary] = BranchingParser.build_condition_nodes(
		headers,
		line_ids,
		"after_block",
		PackedStringArray(["true_a", "true_b", "true_else"])
	)
	assert_eq(nodes.size(), 3)
	assert_true(CompiledLine.validate(nodes[0]))
	assert_eq(nodes[0][CompiledLine.KEY_NEXT_SIBLING_ID], "c_elif")
	assert_eq(nodes[1][CompiledLine.KEY_NEXT_SIBLING_ID], "c_else")
	assert_eq(nodes[2][CompiledLine.KEY_NEXT_SIBLING_ID], "")
	assert_eq(nodes[0][CompiledLine.KEY_NEXT_ID_AFTER], "after_block")
	assert_eq(nodes[2][CompiledLine.KEY_NEXT_ID_AFTER], "after_block")
	assert_eq(nodes[0][CompiledLine.KEY_NEXT_ID], "true_a")
	assert_eq(nodes[2][CompiledLine.KEY_NEXT_ID], "true_else")


func test_rejects_invalid_branch_sequence() -> void:
	var headers: Array[Dictionary] = [BranchingParser.parse_header("elif flag(\"x\"):", 1)]
	assert_false(BranchingParser.validate_branch_sequence(headers))
	assert_true(BranchingParser.build_condition_nodes(headers, PackedStringArray(["c1"]), "after").is_empty())
