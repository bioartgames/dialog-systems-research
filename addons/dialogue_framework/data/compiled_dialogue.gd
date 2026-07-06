class_name CompiledDialogue
extends Resource


@export var resource_uid: String = ""
@export var source_path: String = ""
@export var raw_text: String = ""
@export var format_version: int = DialogueFrameworkVersions.FORMAT_VERSION
@export var compiler_version: int = DialogueFrameworkVersions.COMPILER_VERSION
@export var titles: Dictionary = {}
@export var lines: Dictionary = {}
@export var first_title: String = ""


func get_line(line_id: String) -> Dictionary:
	return lines.get(line_id, {}) as Dictionary


func has_line(line_id: String) -> bool:
	return lines.has(line_id)


func get_title_line_id(title_name: String) -> String:
	return String(titles.get(title_name, ""))
