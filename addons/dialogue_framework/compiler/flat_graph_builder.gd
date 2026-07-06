class_name FlatGraphBuilder
extends RefCounted


static func build(
	source_text: String,
	source_path: String,
	flag_manifest: FlagManifest = null,
	command_manifest: CommandManifest = null
) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()

	if not DlgLexer.validate_single_file_scope(source_text, source_path):
		errors.append_array(DlgSingleFileScopeEnforcer.get_violations(source_text, source_path))
		return _empty_result(errors, warnings)

	var tokens: Array[Dictionary] = DlgLexer.tokenize(source_text)
	var built_lines: Array[Dictionary] = []
	var title_entries: Array[Dictionary] = []
	var title_names: PackedStringArray = PackedStringArray()
	var title_line_ids: PackedStringArray = PackedStringArray()
	var branch_headers: Array[Dictionary] = []
	var branch_header_ids: PackedStringArray = PackedStringArray()

	for token: Dictionary in tokens:
		if bool(token.get(DlgLexer.KEY_IS_EMPTY, false)):
			continue
		var raw_line: String = String(token.get(DlgLexer.KEY_RAW_LINE, ""))
		var text: String = String(token.get(DlgLexer.KEY_TEXT, ""))
		var source_line_number: int = int(token.get(DlgLexer.KEY_SOURCE_LINE_NUMBER, 0))
		var line_id: String = LineIdGenerator.resolve_line_id(raw_line, source_path, source_line_number)
		var content: String = LineIdOverrideParser.strip_override_prefix(raw_line)

		if TitleEntryParser.matches(text):
			var parsed_title: Dictionary = TitleEntryParser.parse(text, source_line_number)
			if parsed_title.is_empty():
				errors.append("Invalid title entry at line %d." % source_line_number)
				continue
			title_names.append(String(parsed_title["title_name"]))
			title_entries.append(parsed_title)
			title_line_ids.append(line_id)
			built_lines.append({
				"id": line_id,
				"line": CompiledLine.create_title(line_id, source_line_number, "", parsed_title["title_name"]),
			})
			continue

		if BranchingParser.matches_header(content):
			_flush_branch_headers(branch_headers, branch_header_ids, built_lines, errors)
			var header: Dictionary = BranchingParser.parse_header(raw_line, source_line_number)
			if header.is_empty():
				errors.append("Invalid branch header at line %d." % source_line_number)
				continue
			branch_headers.append(header)
			branch_header_ids.append(line_id)
			continue

		_flush_branch_headers(branch_headers, branch_header_ids, built_lines, errors)

		if ChoiceLineParser.matches(text):
			var parsed_choice: Dictionary = ChoiceLineParser.parse(text, source_line_number)
			if parsed_choice.is_empty():
				errors.append("Invalid choice line at line %d." % source_line_number)
				continue
			built_lines.append({
				"id": line_id,
				"line": ChoiceLineParser.build_choice_line(line_id, "", parsed_choice),
			})
			continue

		if CommandLineParser.matches(text):
			var parsed_command: Dictionary = CommandLineParser.parse(text, source_line_number)
			if parsed_command.is_empty():
				errors.append("Invalid command line at line %d." % source_line_number)
				continue
			var command_name: String = String(parsed_command["command_name"])
			if not _is_allowed_command(command_name, command_manifest, errors, source_line_number):
				continue
			var args: Array = Array(parsed_command.get("args", PackedStringArray()))
			built_lines.append({
				"id": line_id,
				"line": CompiledLine.create_command(
					line_id,
					source_line_number,
					"",
					command_name,
					args
				),
			})
			continue

		if GotoLineParser.matches(text):
			var parsed_goto: Dictionary = GotoLineParser.parse(text, source_line_number)
			if parsed_goto.is_empty():
				errors.append("Invalid goto line at line %d." % source_line_number)
				continue
			built_lines.append({
				"id": line_id,
				"line": GotoLineParser.build_compiled_node(line_id, "", parsed_goto),
			})
			continue

		if DialogueLineParser.matches(content):
			var parsed_dialogue: Dictionary = DialogueLineParser.parse(content, source_line_number)
			if parsed_dialogue.is_empty():
				errors.append("Invalid dialogue line at line %d." % source_line_number)
				continue
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
			continue

		errors.append("Unrecognized line at %d." % source_line_number)

	_flush_branch_headers(branch_headers, branch_header_ids, built_lines, errors)
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


static func _flush_branch_headers(
	branch_headers: Array[Dictionary],
	branch_header_ids: PackedStringArray,
	built_lines: Array[Dictionary],
	errors: PackedStringArray
) -> void:
	if branch_headers.is_empty():
		return
	if not BranchingParser.validate_branch_sequence(branch_headers):
		errors.append("Invalid if/elif/else sequence.")
		branch_headers.clear()
		branch_header_ids.clear()
		return
	var condition_nodes: Array[Dictionary] = BranchingParser.build_condition_nodes(
		branch_headers,
		branch_header_ids,
		"",
		PackedStringArray()
	)
	for index: int in condition_nodes.size():
		built_lines.append({
			"id": branch_header_ids[index],
			"line": condition_nodes[index],
		})
	branch_headers.clear()
	branch_header_ids.clear()


static func _wire_next_ids(built_lines: Array[Dictionary]) -> void:
	for index: int in built_lines.size():
		var next_id: String = ""
		if index < built_lines.size() - 1:
			next_id = String(built_lines[index + 1]["id"])
		built_lines[index]["line"][CompiledLine.KEY_NEXT_ID] = next_id


static func _is_allowed_command(
	command_name: String,
	command_manifest: CommandManifest,
	errors: PackedStringArray,
	source_line_number: int
) -> bool:
	if CommandManifest.is_built_in_command(command_name):
		return true
	if command_manifest != null and command_manifest.is_valid_command(command_name):
		return true
	if command_manifest == null and DialogueFrameworkProjectSettings.get_command_manifest_path().is_empty():
		errors.append(
			"Unknown command '%s' at line %d; configure CommandManifest for game commands."
			% [command_name, source_line_number]
		)
		return false
	errors.append("Unknown command '%s' at line %d." % [command_name, source_line_number])
	return false


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
