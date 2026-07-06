extends GutTest


func test_plugin_script_is_editor_plugin_tool() -> void:
	var script: Script = load("res://addons/dialogue_framework/plugin.gd")
	assert_not_null(script)
	assert_true(script.is_tool())
	assert_true(script.can_instantiate())


func test_plugin_exposes_import_plugin_hook() -> void:
	var script: Script = load("res://addons/dialogue_framework/plugin.gd")
	var method_names: PackedStringArray = PackedStringArray()
	for method: Dictionary in script.get_script_method_list():
		method_names.append(String(method.get("name")))
	assert_true(method_names.has("set_dialogue_import_plugin"))
