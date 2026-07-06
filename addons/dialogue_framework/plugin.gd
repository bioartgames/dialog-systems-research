@tool
extends EditorPlugin


var _import_plugin: EditorImportPlugin


func _enter_tree() -> void:
	DialogueFrameworkProjectSettings.register_settings()
	_register_import_plugin_hook()


func _exit_tree() -> void:
	_unregister_import_plugin_hook()


func _register_import_plugin_hook() -> void:
	pass


func _unregister_import_plugin_hook() -> void:
	if _import_plugin == null:
		return
	remove_import_plugin(_import_plugin)
	_import_plugin = null


func set_dialogue_import_plugin(import_plugin: EditorImportPlugin) -> void:
	_unregister_import_plugin_hook()
	_import_plugin = import_plugin
	if _import_plugin != null:
		add_import_plugin(_import_plugin)
