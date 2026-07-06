extends GutTest


const CONTROLLER_PATH := "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const PLUGIN_PATH := "res://addons/dialogue_framework/plugin.gd"


func test_conversation_controller_script_has_no_global_class_name() -> void:
	var script: Script = load(CONTROLLER_PATH)
	assert_not_null(script)
	assert_eq(script.get_global_name(), &"")
	var instance: Node = script.new()
	add_child_autofree(instance)
	assert_true(instance is Node)


func test_plugin_registers_autoload_lifecycle_hooks() -> void:
	var script: Script = load(PLUGIN_PATH)
	var method_names: PackedStringArray = PackedStringArray()
	for method: Dictionary in script.get_script_method_list():
		method_names.append(String(method.get("name")))
	assert_true(method_names.has("_enable_plugin"))
	assert_true(method_names.has("_disable_plugin"))


func test_project_autoload_points_at_conversation_controller() -> void:
	var path: String = String(ProjectSettings.get_setting("autoload/ConversationController", ""))
	assert_false(path.is_empty())
	assert_true(path.contains("conversation_controller.gd"))
