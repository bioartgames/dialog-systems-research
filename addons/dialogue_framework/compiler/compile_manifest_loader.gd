class_name CompileManifestLoader
extends RefCounted


enum ValidationMode {
	EDITOR_IMPORT,
	STRICT,
}


static func load_for_compile(
	validation_mode: ValidationMode = ValidationMode.EDITOR_IMPORT
) -> Dictionary:
	var warnings: PackedStringArray = PackedStringArray()
	var errors: PackedStringArray = PackedStringArray()
	var strict: bool = validation_mode == ValidationMode.STRICT
	var flag_manifest: FlagManifest = FlagManifest.load_from_project_settings()
	var command_manifest: CommandManifest = CommandManifest.load_from_project_settings()

	_append_flag_manifest_status(flag_manifest, strict, warnings, errors)
	_append_command_manifest_status(command_manifest, strict, warnings, errors)

	return {
		"flag_manifest": flag_manifest,
		"command_manifest": command_manifest,
		"warnings": warnings,
		"errors": errors,
	}


static func _append_flag_manifest_status(
	flag_manifest: FlagManifest,
	strict: bool,
	warnings: PackedStringArray,
	errors: PackedStringArray
) -> void:
	var path: String = DialogueFrameworkProjectSettings.get_flag_manifest_path()
	if flag_manifest != null:
		return
	if path.is_empty():
		if strict:
			errors.append("FlagManifest path is not configured.")
		else:
			warnings.append("FlagManifest path is not configured; skipping flag validation.")
		return
	if strict:
		errors.append("FlagManifest failed to load: %s" % path)
	else:
		warnings.append("FlagManifest failed to load: %s; skipping flag validation." % path)


static func _append_command_manifest_status(
	command_manifest: CommandManifest,
	strict: bool,
	warnings: PackedStringArray,
	errors: PackedStringArray
) -> void:
	var path: String = DialogueFrameworkProjectSettings.get_command_manifest_path()
	if command_manifest != null or path.is_empty():
		return
	if strict:
		errors.append("CommandManifest failed to load: %s" % path)
	else:
		warnings.append("CommandManifest failed to load: %s" % path)
