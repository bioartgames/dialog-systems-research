class_name CommandManifestValidator
extends RefCounted


static func validate_command(
	command_name: String,
	command_manifest: CommandManifest,
	strict: bool,
	source_line_number: int
) -> Dictionary:
	if CommandManifest.is_built_in_command(command_name):
		return {"allowed": true, "error": ""}

	var manifest_path: String = DialogueFrameworkProjectSettings.get_command_manifest_path()
	if command_manifest != null and command_manifest.is_valid_command(command_name):
		return {"allowed": true, "error": ""}

	if manifest_path.is_empty():
		if strict:
			return {
				"allowed": false,
				"error": (
					"Unknown command '%s' at line %d; CommandManifest path is required in strict mode."
					% [command_name, source_line_number]
				),
			}
		return {
			"allowed": false,
			"error": (
				"Unknown command '%s' at line %d; configure CommandManifest for game commands."
				% [command_name, source_line_number]
			),
		}

	if command_manifest == null:
		if strict:
			return {
				"allowed": false,
				"error": (
					"Unknown command '%s' at line %d; CommandManifest failed to load."
					% [command_name, source_line_number]
				),
			}
		return {
			"allowed": false,
			"error": "Unknown command '%s' at line %d." % [command_name, source_line_number],
		}

	return {
		"allowed": false,
		"error": "Unknown command '%s' at line %d." % [command_name, source_line_number],
	}
