@tool
class_name DlgImportPlugin
extends EditorImportPlugin


func _get_importer_name() -> String:
	return "dialogue_framework.dlg"


func _get_visible_name() -> String:
	return "Dialogue (.dlg)"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["dlg"])


func _get_save_extension() -> String:
	return "tres"


func _get_resource_type() -> String:
	return "Resource"


func _get_priority() -> float:
	return 1.0


func _import(
	source_file: String,
	save_path: String,
	_options: Dictionary,
	_platform_variants: Array[String],
	_gen_files: Array[String]
) -> Error:
	var source_text: String = FileAccess.get_file_as_string(source_file)
	var compile_result: Dictionary = DialogueCompiler.compile(source_text, source_file, false)
	var errors: PackedStringArray = compile_result.get("errors", PackedStringArray())
	if not errors.is_empty():
		for error_message: String in errors:
			push_error(error_message)
		return ERR_CANT_CREATE
	var compiled: CompiledDialogue = compile_result.get("compiled")
	if compiled == null:
		push_error("Dialogue compile failed for %s" % source_file)
		return ERR_CANT_CREATE
	return ResourceSaver.save(compiled, "%s.%s" % [save_path, _get_save_extension()])
