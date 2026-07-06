@tool
extends EditorPlugin


func _enter_tree() -> void:
	DialogueFrameworkProjectSettings.register_settings()


func _exit_tree() -> void:
	pass
