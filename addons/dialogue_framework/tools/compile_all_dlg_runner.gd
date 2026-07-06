class_name CompileAllDlgRunner
extends RefCounted


const DEFAULT_SCAN_ROOT := "res://"
const SKIP_DIR_NAMES: Array[String] = [".godot", ".git"]


static func collect_dlg_files(scan_root: String = DEFAULT_SCAN_ROOT) -> PackedStringArray:
	var paths: PackedStringArray = PackedStringArray()
	_collect_dlg_files_recursive(scan_root, paths)
	paths.sort()
	return paths


static func run(strict: bool = false, scan_root: String = DEFAULT_SCAN_ROOT) -> Dictionary:
	DialogueFrameworkProjectSettings.register_settings()
	var dlg_files: PackedStringArray = collect_dlg_files(scan_root)
	var errors: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	var compiled_count: int = 0
	for dlg_path: String in dlg_files:
		var file_result: Dictionary = _compile_dlg_file(dlg_path, strict)
		warnings.append_array(file_result.get("warnings", PackedStringArray()))
		errors.append_array(file_result.get("errors", PackedStringArray()))
		if file_result.get("success", false):
			compiled_count += 1
	return {
		"compiled_count": compiled_count,
		"dlg_file_count": dlg_files.size(),
		"dlg_files": dlg_files,
		"errors": errors,
		"warnings": warnings,
		"strict": strict,
	}


static func _compile_dlg_file(dlg_path: String, strict: bool) -> Dictionary:
	if not FileAccess.file_exists(dlg_path):
		return {
			"success": false,
			"errors": PackedStringArray(["%s: file not found." % dlg_path]),
			"warnings": PackedStringArray(),
		}
	var source_text: String = FileAccess.get_file_as_string(dlg_path)
	var compile_result: Dictionary = DialogueCompiler.compile(source_text, dlg_path, strict)
	var warnings: PackedStringArray = compile_result.get("warnings", PackedStringArray()).duplicate()
	var compile_errors: PackedStringArray = compile_result.get("errors", PackedStringArray()).duplicate()
	var prefixed_errors: PackedStringArray = PackedStringArray()
	for error_message: String in compile_errors:
		prefixed_errors.append("%s: %s" % [dlg_path, error_message])
	if compile_errors.is_empty() and compile_result.get("compiled") == null:
		prefixed_errors.append("%s: compile produced no CompiledDialogue resource." % dlg_path)
	return {
		"success": compile_errors.is_empty() and compile_result.get("compiled") != null,
		"errors": prefixed_errors,
		"warnings": warnings,
	}


static func _collect_dlg_files_recursive(dir_path: String, out: PackedStringArray) -> void:
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
			if SKIP_DIR_NAMES.has(entry_name):
				entry_name = dir.get_next()
				continue
			_collect_dlg_files_recursive(full_path, out)
		elif entry_name.ends_with(".dlg"):
			out.append(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
