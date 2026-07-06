extends GutTest


const PACKAGE_ROOT := "res://addons/dialogue_framework/"
const FIXTURE_PATH := "res://addons/dialogue_framework/tests/fixtures/minimal.dlg"
const OPEN_QUESTIONS_PATH := "res://docs/architecture/dialogue/05-open-questions.md"
const PLUGIN_PATH := "res://addons/dialogue_framework/plugin.gd"
const IMPORT_PLUGIN_PATH := "res://addons/dialogue_framework/compiler/dlg_import_plugin.gd"
const RUNTIME_ROOT := "res://addons/dialogue_framework/runtime/"
const TESTS_UNIT_ROOT := "res://addons/dialogue_framework/tests/unit/"

const FORBIDDEN_VISUAL_EDITOR_MARKERS: PackedStringArray = [
	"add_control_to_container",
	"make_bottom_panel_item",
	"add_inspector_plugin",
	"GraphEdit",
	"DialogueEditor",
	"visual_editor",
]

const FORBIDDEN_PLAYTEST_MARKERS: PackedStringArray = [
	"playtest",
	"Playtest",
	"preview_conversation",
	"run_dialogue_in_editor",
]

const D16_1_VALIDATION_TEST_FILES: PackedStringArray = [
	"test_golden_compile_snapshots.gd",
	"test_conversation_controller_integration.gd",
	"test_dialogue_compiler.gd",
	"test_flat_graph_builder.gd",
]


func _collect_gd_files(dir_path: String, out: Array[String], skip_tests: bool = false) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = dir.get_next()
			continue
		var full_path: String = dir_path.path_join(entry_name)
		if dir.current_is_dir():
			if skip_tests and entry_name == "tests":
				entry_name = dir.get_next()
				continue
			_collect_gd_files(full_path, out, skip_tests)
		elif entry_name.ends_with(".gd"):
			out.append(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()


func _read_file_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _find_forbidden_markers(paths: Array[String], markers: PackedStringArray) -> Array[String]:
	var hits: Array[String] = []
	for file_path: String in paths:
		var text: String = _read_file_text(file_path)
		for marker: String in markers:
			if text.contains(marker):
				hits.append("%s contains '%s'" % [file_path, marker])
	return hits


func test_compile_string_preserves_canonical_raw_text() -> void:
	var source_text: String = _read_file_text(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, FIXTURE_PATH)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var compiled: CompiledDialogue = result["compiled"]
	assert_eq(compiled.raw_text, source_text)
	assert_eq(compiled.source_path, FIXTURE_PATH)


func test_compile_api_used_by_import_preserves_raw_text() -> void:
	var source_text: String = _read_file_text(FIXTURE_PATH)
	var result: Dictionary = DialogueCompiler.compile(source_text, FIXTURE_PATH, false)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	assert_eq(result["compiled"].raw_text, source_text)


func test_dlg_is_only_recognized_authoring_import_extension() -> void:
	var script: Script = load(IMPORT_PLUGIN_PATH)
	assert_not_null(script)
	assert_true(script.is_tool())
	var source_text: String = _read_file_text(IMPORT_PLUGIN_PATH)
	assert_true(source_text.contains('return PackedStringArray(["dlg"])'))
	assert_true(source_text.contains('return "tres"'))


func test_runtime_does_not_invoke_compiler_authoring_path() -> void:
	var runtime_files: Array[String] = []
	_collect_gd_files(RUNTIME_ROOT, runtime_files)
	assert_false(runtime_files.is_empty())
	for file_path: String in runtime_files:
		var text: String = _read_file_text(file_path)
		assert_false(text.contains("DialogueCompiler"), "Runtime must not compile authoring text: %s" % file_path)
		assert_false(text.contains("compile_string"), "Runtime must not expose dev compile API: %s" % file_path)


func test_no_alternate_authoring_importer_in_addon() -> void:
	var addon_files: Array[String] = []
	_collect_gd_files(PACKAGE_ROOT, addon_files, true)
	var import_plugin_count: int = 0
	for file_path: String in addon_files:
		var text: String = _read_file_text(file_path)
		if text.contains("extends EditorImportPlugin"):
			import_plugin_count += 1
			assert_true(
				file_path.ends_with("dlg_import_plugin.gd"),
				"Only DlgImportPlugin may import dialogue sources: %s" % file_path
			)
	assert_eq(import_plugin_count, 1)


func test_open_questions_documents_deferred_editor_scope() -> void:
	var text: String = _read_file_text(OPEN_QUESTIONS_PATH)
	assert_true(text.contains("Deferred indefinitely"), "D19.1 deferred status missing")
	assert_true(text.contains("Deferred; use game run"), "D19.4 deferred status missing")
	assert_true(text.contains("`.dlg` text as canonical source"), "D19.2 canonical source missing")


func test_addon_excludes_visual_editor_code() -> void:
	var addon_files: Array[String] = []
	_collect_gd_files(PACKAGE_ROOT, addon_files, true)
	var hits: Array[String] = _find_forbidden_markers(addon_files, FORBIDDEN_VISUAL_EDITOR_MARKERS)
	assert_true(hits.is_empty(), "Visual editor markers found:\n" + "\n".join(hits))


func test_plugin_registers_import_only_not_editor_ui() -> void:
	var plugin_text: String = _read_file_text(PLUGIN_PATH)
	assert_true(plugin_text.contains("add_import_plugin"))
	assert_false(plugin_text.contains("add_control_to_container"))
	assert_false(plugin_text.contains("make_bottom_panel_item"))
	assert_false(plugin_text.contains("add_inspector_plugin"))


func test_addon_excludes_in_editor_playtest_tooling() -> void:
	var addon_files: Array[String] = []
	_collect_gd_files(PACKAGE_ROOT, addon_files, true)
	var hits: Array[String] = _find_forbidden_markers(addon_files, FORBIDDEN_PLAYTEST_MARKERS)
	assert_true(hits.is_empty(), "Playtest tooling markers found:\n" + "\n".join(hits))


func test_validation_harness_covers_dialogue_compiler_and_controller() -> void:
	for test_file: String in D16_1_VALIDATION_TEST_FILES:
		var path: String = TESTS_UNIT_ROOT + test_file
		assert_true(FileAccess.file_exists(path), "Missing D16.1 validation test: %s" % path)
