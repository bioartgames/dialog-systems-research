extends GutTest


const PACKAGE_ROOT := "res://addons/dialogue_framework/"
const RUNTIME_ROOT := "res://addons/dialogue_framework/runtime/"
const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const RUNNER_PATH := "res://addons/dialogue_framework/runtime/dialogue_runner.gd"
const PROJECT_GOALS_PATH := "res://docs/architecture/dialogue/00-project-goals.md"
const README_PATH := "res://addons/dialogue_framework/README.md"

const FORBIDDEN_VARIABLE_STORE_MARKERS: PackedStringArray = [
	"VariableStore",
	"variable_store",
	"set_dialogue_variable",
	"get_dialogue_variable",
	"DialogueVariables",
]

const V1_NON_GOAL_COMPILE_CHECKS: Array[Dictionary] = [
	{
		"label": "#portrait tag (D11.4)",
		"source": "~ start\nRoll: Hi #portrait=roll\n",
		"path": "res://test/non_goal_portrait.dlg",
		"error_substring": "portrait",
	},
	{
		"label": "inline text conditionals (D8.4)",
		"source": "~ start\nRoll: Hello [if flag(\"x\")]there[/if]\n",
		"path": "res://test/non_goal_inline_cond.dlg",
		"error_substring": "Inline text conditionals",
	},
	{
		"label": "cross-file import (D5.5)",
		"source": "import res://other.dlg\n~ start\n",
		"path": "res://test/non_goal_import.dlg",
		"error_substring": "Cross-file import",
	},
]


func _collect_gd_files(dir_path: String, out: Array[String]) -> void:
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
			_collect_gd_files(full_path, out)
		elif entry_name.ends_with(".gd"):
			out.append(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()


func _read_file_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_no_framework_owned_variable_store_in_runtime() -> void:
	var runtime_files: Array[String] = []
	_collect_gd_files(RUNTIME_ROOT, runtime_files)
	var hits: Array[String] = []
	for file_path: String in runtime_files:
		var text: String = _read_file_text(file_path)
		for marker: String in FORBIDDEN_VARIABLE_STORE_MARKERS:
			if text.contains(marker):
				hits.append("%s contains '%s'" % [file_path, marker])
	assert_true(hits.is_empty(), "Framework variable store markers found:\n" + "\n".join(hits))
	var game_context_script: Script = load("res://addons/dialogue_framework/runtime/game_context.gd")
	assert_true(game_context_script.is_abstract())


func test_controller_runner_dto_layer_separation() -> void:
	var controller_text: String = _read_file_text(CONTROLLER_PATH)
	var runner_text: String = _read_file_text(RUNNER_PATH)
	assert_true(controller_text.contains("DialogueRunner"))
	assert_true(controller_text.contains("ConversationStep"))
	assert_true(controller_text.contains("IDialoguePresenter"))
	assert_false(runner_text.contains("IDialoguePresenter"))
	assert_false(runner_text.contains("extends Node"))
	var runner_script: Script = load(RUNNER_PATH)
	assert_eq(runner_script.get_global_name(), &"DialogueRunner")


func test_runtime_excludes_compile_at_import_boundary() -> void:
	var runtime_files: Array[String] = []
	_collect_gd_files(RUNTIME_ROOT, runtime_files)
	for file_path: String in runtime_files:
		var text: String = _read_file_text(file_path)
		assert_false(text.contains("DialogueCompiler"), "Runtime must not parse .dlg: %s" % file_path)
		assert_false(text.contains("FlatGraphBuilder"), "Runtime must not build graphs: %s" % file_path)


func test_v1_non_goals_rejected_at_compile_time() -> void:
	for check: Dictionary in V1_NON_GOAL_COMPILE_CHECKS:
		var result: Dictionary = DialogueCompiler.compile_string(
			String(check["source"]),
			String(check["path"])
		)
		assert_false(result["errors"].is_empty(), "Expected compile failure for %s" % check["label"])
		var combined_errors: String = str(result["errors"])
		assert_true(
			combined_errors.contains(String(check["error_substring"])),
			"Expected '%s' in errors for %s" % [check["error_substring"], check["label"]]
		)


func test_line_kind_enum_is_closed_v1_set() -> void:
	assert_eq(LineKind.Kind.TITLE, 0)
	assert_eq(LineKind.Kind.END, 6)
	assert_eq(LineKind.Kind.keys().size(), 7)


func test_single_conversation_controller_autoload_facade() -> void:
	var autoload_path: String = String(ProjectSettings.get_setting("autoload/ConversationController", ""))
	assert_false(autoload_path.is_empty())
	assert_true(autoload_path.contains("conversation_controller.gd"))
	var plugin_text: String = _read_file_text("res://addons/dialogue_framework/plugin.gd")
	assert_true(plugin_text.contains('AUTOLOAD_NAME := "ConversationController"'))


func test_start_rejects_nested_conversations() -> void:
	var compiled: CompiledDialogue = DialogueCompiler.compile_string(
		"~ start\nRoll: Hi.\n",
		"res://test/nested_conv.dlg"
	)["compiled"]
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	var presenter: IDialoguePresenter = load(
		"res://addons/dialogue_framework/tests/helpers/mock_dialogue_presenter.gd"
	).new()
	add_child_autofree(presenter)
	var controller: Node = load(CONTROLLER_PATH).new()
	add_child_autofree(controller)
	assert_true(controller.start(compiled, "start", context, presenter))
	assert_false(controller.start(compiled, "start", context, presenter))


func test_runner_and_evaluator_instantiate_without_scene_tree() -> void:
	var runner: DialogueRunner = DialogueRunner.new()
	var evaluator: ConditionEvaluator = ConditionEvaluator.new()
	assert_true(runner is RefCounted)
	assert_true(evaluator is RefCounted)
	assert_eq(runner.get_class(), "RefCounted")
	assert_eq(evaluator.get_class(), "RefCounted")


func test_project_goals_and_readme_document_d1_philosophy() -> void:
	var goals_text: String = _read_file_text(PROJECT_GOALS_PATH)
	assert_true(goals_text.contains("Game-authoritative state"))
	assert_true(goals_text.contains("Layered interpreter"))
	assert_true(goals_text.contains("Compile at import"))
	var readme_text: String = _read_file_text(README_PATH)
	assert_true(readme_text.contains("001-philosophy-and-scope.md"))
