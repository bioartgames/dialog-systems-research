extends GutTest


const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"


func test_compile_string_produces_compiled_dialogue_resource() -> void:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var compiled: CompiledDialogue = result["compiled"]
	assert_not_null(compiled)
	assert_eq(compiled.source_path, FIXTURE_PATH)
	assert_false(compiled.lines.is_empty())
	assert_eq(compiled.first_title, "start")
	assert_eq(compiled.resource_uid, FIXTURE_PATH)


func test_compile_sets_translation_key_on_all_line_nodes() -> void:
	var source_text: String = (
		"~ start\n"
		+ "[id:quest_intro] Roll: Welcome.\n"
		+ "Roll: Fallback line.\n"
	)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	for line_id: String in result["compiled"].lines:
		var line: Dictionary = result["compiled"].lines[line_id]
		if CompiledLine.get_kind(line) != LineKind.Kind.LINE:
			continue
		var translation_key: String = String(line.get(CompiledLine.KEY_TRANSLATION_KEY, ""))
		assert_false(translation_key.is_empty(), "LINE %s missing translation_key" % line_id)
	var line_count: int = 0
	for line_id: String in result["compiled"].lines:
		if CompiledLine.get_kind(result["compiled"].lines[line_id]) == LineKind.Kind.LINE:
			line_count += 1
	assert_eq(line_count, 2)
	var intro_line: Dictionary = {}
	for line_id: String in result["compiled"].lines:
		var line: Dictionary = result["compiled"].lines[line_id]
		if line.get(CompiledLine.KEY_TEXT) == "Welcome.":
			intro_line = line
	assert_eq(intro_line[CompiledLine.KEY_TRANSLATION_KEY], "quest_intro")


func test_compile_stores_condition_tokens_on_branch_and_choice_nodes() -> void:
	var source_text: String = (
		"~ start\n"
		+ "if flag(\"met_roll\"):\n"
		+ "    Roll: Seen you before.\n"
		+ "else:\n"
		+ "    Roll: Who are you?\n"
		+ "- Secret | if flag(\"quest_done\") => END\n"
	)
	var result: Dictionary = FlatGraphBuilder.build(
		source_text,
		"res://test/conditions.dlg",
		null,
		null,
		false
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var condition_tokens_found: bool = false
	var choice_tokens_found: bool = false
	for line_id: String in result["lines"]:
		var line: Dictionary = result["lines"][line_id]
		if CompiledLine.get_kind(line) == LineKind.Kind.CONDITION:
			var tokens: Array = line.get(CompiledLine.KEY_CONDITION_TOKENS, [])
			if not tokens.is_empty():
				condition_tokens_found = true
				assert_eq(tokens[0], {"type": "call", "function": "flag", "arg": "met_roll"})
		elif CompiledLine.get_kind(line) == LineKind.Kind.CHOICE:
			var choice_tokens: Array = line.get(CompiledLine.KEY_CONDITION_TOKENS, [])
			if not choice_tokens.is_empty():
				choice_tokens_found = true
				assert_eq(choice_tokens[0], {"type": "call", "function": "flag", "arg": "quest_done"})
	assert_true(condition_tokens_found)
	assert_true(choice_tokens_found)


func test_dlg_import_plugin_exposes_required_import_methods() -> void:
	var script: Script = load("res://addons/dialogue_framework/compiler/dlg_import_plugin.gd")
	assert_not_null(script)
	assert_true(script.is_tool())
	var method_names: PackedStringArray = PackedStringArray()
	for method: Dictionary in script.get_script_method_list():
		method_names.append(String(method.get("name")))
	assert_true(method_names.has("_get_recognized_extensions"))
	assert_true(method_names.has("_import"))


func test_compile_errors_block_compiled_resource_output() -> void:
	var result: Dictionary = DialogueCompiler.compile_string(
		"not valid dialogue syntax",
		"res://test/invalid.dlg"
	)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])


func test_compile_unknown_game_command_fails_without_manifest() -> void:
	var setting_name: String = DialogueFrameworkProjectSettings.setting_name(
		DialogueFrameworkProjectSettings.COMMAND_MANIFEST_PATH
	)
	var previous: Variant = ProjectSettings.get_setting(setting_name)
	ProjectSettings.set_setting(setting_name, "")
	var result: Dictionary = DialogueCompiler.compile_string(
		"~ start\n@open_shop store\n=> END\n",
		"res://test/unknown_command.dlg"
	)
	ProjectSettings.set_setting(setting_name, previous)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])


func test_compile_string_matches_compile_result() -> void:
	var source_text: String = FileAccess.get_file_as_string(FIXTURE_PATH)
	var compile_result: Dictionary = DialogueCompiler.compile(source_text, FIXTURE_PATH, false)
	var compile_string_result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH, false)
	assert_eq(compile_result["errors"], compile_string_result["errors"])
	assert_eq(compile_result["warnings"], compile_string_result["warnings"])
	assert_not_null(compile_string_result["compiled"])
	assert_eq(
		compile_string_result["compiled"].first_title,
		compile_result["compiled"].first_title
	)


func test_compile_string_strict_errors_without_flag_manifest() -> void:
	var setting_name: String = DialogueFrameworkProjectSettings.setting_name(
		DialogueFrameworkProjectSettings.FLAG_MANIFEST_PATH
	)
	var previous: Variant = ProjectSettings.get_setting(setting_name)
	ProjectSettings.set_setting(setting_name, "")
	var result: Dictionary = DialogueCompiler.compile_string("~ start\nRoll: Hi.", "", true)
	ProjectSettings.set_setting(setting_name, previous)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])


func test_dlg_import_plugin_uses_compile_entry_point() -> void:
	var source_text: String = FileAccess.get_file_as_string(
		"res://addons/dialogue_framework/compiler/dlg_import_plugin.gd"
	)
	assert_true(source_text.contains("DialogueCompiler.compile("))
	assert_false(source_text.contains("compile_string("))
