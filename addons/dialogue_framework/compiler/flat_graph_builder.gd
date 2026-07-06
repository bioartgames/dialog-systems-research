class_name FlatGraphBuilder
extends RefCounted


static func build(
	source_text: String,
	source_path: String,
	flag_manifest: FlagManifest = null,
	command_manifest: CommandManifest = null,
	strict: bool = false
) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()

	var stage_one: Dictionary = RawLineProcessor.process(source_text, source_path)
	errors.append_array(stage_one.get("errors", PackedStringArray()))
	if not errors.is_empty():
		return _empty_result(errors, warnings)

	var normalized_lines: Array[Dictionary] = stage_one.get("normalized_lines", [])
	var stage_two: Dictionary = IndentTreeBuilder.build(normalized_lines)
	errors.append_array(stage_two.get("errors", PackedStringArray()))
	var root: IndentTreeBuilder.TreeNode = stage_two.get("root")

	var built_lines: Array[Dictionary] = []
	var title_entries: Array[Dictionary] = []
	var title_names: PackedStringArray = PackedStringArray()
	var title_line_ids: PackedStringArray = PackedStringArray()
	_process_siblings(
		root.children,
		source_path,
		flag_manifest,
		command_manifest,
		strict,
		built_lines,
		title_entries,
		title_names,
		title_line_ids,
		errors
	)
	_wire_next_ids(built_lines)

	var lines: Dictionary = {}
	var line_ids: PackedStringArray = PackedStringArray()
	for entry: Dictionary in built_lines:
		var compiled_line: Dictionary = entry["line"]
		if not CompiledLine.validate(compiled_line):
			errors.append("Compiled line failed validation for id '%s'." % String(entry["id"]))
			continue
		lines[entry["id"]] = compiled_line
		line_ids.append(String(entry["id"]))

	var titles: Dictionary = TitleEntryParser.build_title_mapping(title_entries, title_line_ids)
	return {
		"errors": errors,
		"warnings": warnings,
		"lines": lines,
		"titles": titles,
		"first_title": TitleEntryParser.resolve_first_title(title_names),
		"ordered_ids": line_ids,
	}


static func _process_siblings(
	siblings: Array[IndentTreeBuilder.TreeNode],
	source_path: String,
	flag_manifest: FlagManifest,
	command_manifest: CommandManifest,
	strict: bool,
	built_lines: Array[Dictionary],
	title_entries: Array[Dictionary],
	title_names: PackedStringArray,
	title_line_ids: PackedStringArray,
	errors: PackedStringArray
) -> void:
	var index: int = 0
	while index < siblings.size():
		var node: IndentTreeBuilder.TreeNode = siblings[index]
		var content: String = String(node.line.get(RawLineProcessor.KEY_CONTENT, ""))
		if BranchingParser.matches_header(content):
			var branch_nodes: Array[IndentTreeBuilder.TreeNode] = [node]
			index += 1
			while index < siblings.size():
				var next_header: Dictionary = BranchingParser.parse_header(
					String(siblings[index].line.get(RawLineProcessor.KEY_RAW_LINE, "")),
					int(siblings[index].line.get(RawLineProcessor.KEY_SOURCE_LINE_NUMBER, 0))
				)
				if next_header.is_empty():
					break
				var kind: int = int(next_header.get("branch_kind", -1))
				if kind == BranchingParser.BranchKind.IF:
					break
				branch_nodes.append(siblings[index])
				index += 1
			_flush_branch_nodes(branch_nodes, built_lines, errors)
			for branch_node: IndentTreeBuilder.TreeNode in branch_nodes:
				_process_siblings(
					branch_node.children,
					source_path,
					flag_manifest,
					command_manifest,
					strict,
					built_lines,
					title_entries,
					title_names,
					title_line_ids,
					errors
				)
			continue

		_process_normalized_line(
			node.line,
			source_path,
			flag_manifest,
			command_manifest,
			strict,
			built_lines,
			title_entries,
			title_names,
			title_line_ids,
			errors
		)
		_process_siblings(
			node.children,
			source_path,
			flag_manifest,
			command_manifest,
			strict,
			built_lines,
			title_entries,
			title_names,
			title_line_ids,
			errors
		)
		index += 1


static func _process_normalized_line(
	line: Dictionary,
	source_path: String,
	flag_manifest: FlagManifest,
	command_manifest: CommandManifest,
	strict: bool,
	built_lines: Array[Dictionary],
	title_entries: Array[Dictionary],
	title_names: PackedStringArray,
	title_line_ids: PackedStringArray,
	errors: PackedStringArray
) -> void:
	var raw_line: String = String(line.get(RawLineProcessor.KEY_RAW_LINE, ""))
	var text: String = String(line.get(RawLineProcessor.KEY_TEXT, ""))
	var content: String = String(line.get(RawLineProcessor.KEY_CONTENT, ""))
	var source_line_number: int = int(line.get(RawLineProcessor.KEY_SOURCE_LINE_NUMBER, 0))
	var line_id: String = String(line.get(RawLineProcessor.KEY_LINE_ID, ""))

	if TitleEntryParser.matches(text):
		var parsed_title: Dictionary = TitleEntryParser.parse(text, source_line_number)
		if parsed_title.is_empty():
			errors.append("Invalid title entry at line %d." % source_line_number)
			return
		title_names.append(String(parsed_title["title_name"]))
		title_entries.append(parsed_title)
		title_line_ids.append(line_id)
		built_lines.append({
			"id": line_id,
			"line": CompiledLine.create_title(line_id, source_line_number, "", parsed_title["title_name"]),
		})
		return

	if ChoiceLineParser.matches(text):
		var parsed_choice: Dictionary = ChoiceLineParser.parse(text, source_line_number)
		if parsed_choice.is_empty():
			errors.append("Invalid choice line at line %d." % source_line_number)
			return
		built_lines.append({
			"id": line_id,
			"line": ChoiceLineParser.build_choice_line(line_id, "", parsed_choice),
		})
		return

	if CommandLineParser.matches(text):
		var parsed_command: Dictionary = CommandLineParser.parse(text, source_line_number)
		if parsed_command.is_empty():
			errors.append("Invalid command line at line %d." % source_line_number)
			return
		var command_name: String = String(parsed_command["command_name"])
		var validation: Dictionary = CommandManifestValidator.validate_command(
			command_name,
			command_manifest,
			strict,
			source_line_number
		)
		if not bool(validation.get("allowed", false)):
			errors.append(String(validation.get("error", "")))
			return
		var args: Array = Array(parsed_command.get("args", PackedStringArray()))
		built_lines.append({
			"id": line_id,
			"line": CompiledLine.create_command(line_id, source_line_number, "", command_name, args),
		})
		return

	if GotoLineParser.matches(text):
		var parsed_goto: Dictionary = GotoLineParser.parse(text, source_line_number)
		if parsed_goto.is_empty():
			errors.append("Invalid goto line at line %d." % source_line_number)
			return
		built_lines.append({
			"id": line_id,
			"line": GotoLineParser.build_compiled_node(line_id, "", parsed_goto),
		})
		return

	if DialogueLineParser.matches(content):
		var parsed_dialogue: Dictionary = DialogueLineParser.parse(content, source_line_number)
		if parsed_dialogue.is_empty():
			errors.append("Invalid dialogue line at line %d." % source_line_number)
			return
		var dialogue_text: String = String(parsed_dialogue["text"])
		var tag_result: Dictionary = TagParser.extract_tags(dialogue_text)
		errors.append_array(tag_result.get("errors", PackedStringArray()))
		dialogue_text = String(tag_result.get("text", dialogue_text))
		var brace_result: Dictionary = BraceInterpolationParser.extract_keys(dialogue_text)
		errors.append_array(brace_result.get("errors", PackedStringArray()))
		errors.append_array(
			BraceInterpolationParser.validate_keys_against_manifest(
				brace_result.get("keys", PackedStringArray()),
				flag_manifest
			)
		)
		built_lines.append({
			"id": line_id,
			"line": CompiledLine.create_line(
				line_id,
				source_line_number,
				"",
				String(parsed_dialogue["speaker_id"]),
				dialogue_text,
				tag_result.get("tags", PackedStringArray()),
				LineIdGenerator.resolve_translation_key(raw_line, source_path, source_line_number)
			),
		})
		return

	errors.append("Unrecognized line at %d." % source_line_number)


static func _flush_branch_nodes(
	branch_nodes: Array[IndentTreeBuilder.TreeNode],
	built_lines: Array[Dictionary],
	errors: PackedStringArray
) -> void:
	var headers: Array[Dictionary] = []
	var branch_header_ids: PackedStringArray = PackedStringArray()
	for node: IndentTreeBuilder.TreeNode in branch_nodes:
		var header: Dictionary = BranchingParser.parse_header(
			String(node.line.get(RawLineProcessor.KEY_RAW_LINE, "")),
			int(node.line.get(RawLineProcessor.KEY_SOURCE_LINE_NUMBER, 0))
		)
		if header.is_empty():
			errors.append(
				"Invalid branch header at line %d."
				% int(node.line.get(RawLineProcessor.KEY_SOURCE_LINE_NUMBER, 0))
			)
			return
		headers.append(header)
		branch_header_ids.append(String(node.line.get(RawLineProcessor.KEY_LINE_ID, "")))

	if not BranchingParser.validate_branch_sequence(headers):
		errors.append("Invalid if/elif/else sequence.")
		return

	var condition_nodes: Array[Dictionary] = BranchingParser.build_condition_nodes(
		headers,
		branch_header_ids,
		"",
		PackedStringArray()
	)
	for index: int in condition_nodes.size():
		built_lines.append({
			"id": branch_header_ids[index],
			"line": condition_nodes[index],
		})


static func _wire_next_ids(built_lines: Array[Dictionary]) -> void:
	for index: int in built_lines.size():
		var next_id: String = ""
		if index < built_lines.size() - 1:
			next_id = String(built_lines[index + 1]["id"])
		built_lines[index]["line"][CompiledLine.KEY_NEXT_ID] = next_id


static func _empty_result(
	errors: PackedStringArray,
	warnings: PackedStringArray
) -> Dictionary:
	return {
		"errors": errors,
		"warnings": warnings,
		"lines": {},
		"titles": {},
		"first_title": "",
		"ordered_ids": PackedStringArray(),
	}
