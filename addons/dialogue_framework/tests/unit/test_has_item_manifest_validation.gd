extends GutTest


const MANIFEST_PATH := "res://addons/dialogue_framework/tests/fixtures/test_flag_manifest.tres"
const FLAG_SETTING := "dialogue_framework/flag_manifest_path"
const DEFAULT_FLAG_PATH := "res://game/dialogue_demo/resources/flag_manifest.tres"


func before_each() -> void:
	DialogueFrameworkProjectSettings.register_settings()


func after_each() -> void:
	ProjectSettings.set_setting(FLAG_SETTING, DEFAULT_FLAG_PATH)


func _compile_with_project_manifest(source_text: String, path: String) -> Dictionary:
	var previous: Variant = ProjectSettings.get_setting(FLAG_SETTING)
	ProjectSettings.set_setting(FLAG_SETTING, MANIFEST_PATH)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, path)
	ProjectSettings.set_setting(FLAG_SETTING, previous)
	return result


func test_has_item_unknown_id_not_manifest_validated_per_d9_4() -> void:
	var result: Dictionary = _compile_with_project_manifest(
		'~ start\nif has_item("unknown_item"):\n    Roll: Hidden.\nRoll: Visible.\n=> END\n',
		"res://test/has_item_unknown.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	assert_not_null(result["compiled"])


func test_has_item_condition_evaluates_at_runtime() -> void:
	var result: Dictionary = _compile_with_project_manifest(
		'~ start\nif has_item("energy_tank"):\n    Roll: Has tank.\nRoll: Fallback.\n=> END\n',
		"res://test/has_item_runtime.dlg"
	)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	var context: GameContext = load(
		"res://addons/dialogue_framework/tests/helpers/mock_game_context.gd"
	).new()
	context.items["energy_tank"] = 1
	var runner := DialogueRunner.new()
	runner.load(result["compiled"])
	runner.set_game_context(context)
	runner.init_from_title("start")
	var step: ConversationStep = runner.next_step()
	assert_not_null(step)
	assert_eq(step.kind, ConversationStepKind.Kind.LINE)
	assert_eq(step.text, "Has tank.")


func test_flag_unknown_id_still_errors_with_manifest() -> void:
	var result: Dictionary = _compile_with_project_manifest(
		'~ start\nif flag("unknown_flag"):\n    Roll: Hidden.\n=> END\n',
		"res://test/flag_unknown.dlg"
	)
	assert_false(result["errors"].is_empty())
	assert_null(result["compiled"])
