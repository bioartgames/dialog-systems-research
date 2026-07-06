class_name IndentTreeBuilder
extends RefCounted


class TreeNode extends RefCounted:
	var line: Dictionary = {}
	var children: Array[TreeNode] = []


static func build(normalized_lines: Array[Dictionary]) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var root: TreeNode = TreeNode.new()
	var stack: Array[TreeNode] = [root]
	var stack_indents: Array[int] = [-1]

	for line: Dictionary in normalized_lines:
		var indent_level: int = int(line.get(RawLineProcessor.KEY_INDENT_LEVEL, 0))
		while stack_indents.size() > 1 and stack_indents[-1] >= indent_level:
			stack.pop_back()
			stack_indents.pop_back()

		var node: TreeNode = TreeNode.new()
		node.line = line
		stack[-1].children.append(node)

		if _opens_block(line):
			stack.append(node)
			stack_indents.append(indent_level)

	return {
		"root": root,
		"errors": errors,
	}


static func _opens_block(line: Dictionary) -> bool:
	var content: String = String(line.get(RawLineProcessor.KEY_CONTENT, ""))
	return BranchingParser.matches_header(content)
