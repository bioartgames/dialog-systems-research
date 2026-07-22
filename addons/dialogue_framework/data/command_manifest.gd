@tool
class_name CommandManifest
extends Resource


const BUILT_IN_COMMANDS: PackedStringArray = ["wait", "set_flag", "emit"]

## Declared game [code]@command[/code] names for compile-time validation (D9.6).
## Built-ins ([code]wait[/code], [code]set_flag[/code], [code]emit[/code]) are always valid and are not listed here.
@export var commands: PackedStringArray = PackedStringArray()


static func is_built_in_command(command_name: String) -> bool:
	return BUILT_IN_COMMANDS.has(command_name)


static func load_from_project_settings() -> CommandManifest:
	var path: String = DialogueFrameworkProjectSettings.get_command_manifest_path()
	return load_from_path(path)


static func load_from_path(path: String) -> CommandManifest:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("CommandManifest path does not exist: %s" % path)
		return null
	var resource: Resource = load(path)
	if resource is CommandManifest:
		return resource as CommandManifest
	push_error("CommandManifest path does not reference a CommandManifest resource: %s" % path)
	return null


func is_valid_command(command_name: String) -> bool:
	return is_built_in_command(command_name) or commands.has(command_name)
