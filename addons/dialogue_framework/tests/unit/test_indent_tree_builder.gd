extends GutTest


const BRANCHING_PATH := "res://addons/dialogue_framework/tests/fixtures/branching.dlg"


func test_builds_indent_tree_with_block_children() -> void:
	var stage_one: Dictionary = RawLineProcessor.process(
		FileAccess.get_file_as_string(BRANCHING_PATH),
		BRANCHING_PATH
	)
	var stage_two: Dictionary = IndentTreeBuilder.build(stage_one["normalized_lines"])
	var root: IndentTreeBuilder.TreeNode = stage_two["root"]
	assert_gt(root.children.size(), 1)
	var if_node: IndentTreeBuilder.TreeNode = root.children[1]
	assert_gt(if_node.children.size(), 0)
	assert_true(DialogueLineParser.matches(String(if_node.children[0].line[RawLineProcessor.KEY_CONTENT])))


func test_feeds_flat_graph_builder_for_branching_dialogue() -> void:
	var source_text: String = FileAccess.get_file_as_string(BRANCHING_PATH)
	var result: Dictionary = FlatGraphBuilder.build(source_text, BRANCHING_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var kinds: Array[int] = []
	for line_id: String in result["lines"]:
		kinds.append(int(result["lines"][line_id][CompiledLine.KEY_KIND]))
	assert_true(kinds.has(LineKind.Kind.CONDITION))
	assert_true(kinds.has(LineKind.Kind.LINE))
