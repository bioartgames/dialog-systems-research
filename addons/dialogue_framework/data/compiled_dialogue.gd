class_name CompiledDialogue
extends Resource


@export_storage var resource_uid: String = ""
@export_storage var source_path: String = ""
@export_storage var raw_text: String = ""
@export_storage var format_version: int = DialogueFrameworkVersions.FORMAT_VERSION
@export_storage var compiler_version: int = DialogueFrameworkVersions.COMPILER_VERSION
@export_storage var titles: Dictionary = {}
@export_storage var lines: Dictionary = {}
@export_storage var first_title: String = ""


func get_line(line_id: String) -> Dictionary:
	return lines.get(line_id, {}) as Dictionary


func has_line(line_id: String) -> bool:
	return lines.has(line_id)


func get_title_line_id(title_name: String) -> String:
	return String(titles.get(title_name, ""))
