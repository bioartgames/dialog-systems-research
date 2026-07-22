@tool
class_name FlagManifest
extends Resource


## Declared flag names and [code]{brace}[/code] interpolation keys for compile-time validation (D9.4).
## Entries cover both [code]set_flag[/code] / condition flag names and brace keys used in line text.
@export var flags: PackedStringArray = PackedStringArray()


static func load_from_project_settings() -> FlagManifest:
	var path: String = DialogueFrameworkProjectSettings.get_flag_manifest_path()
	return load_from_path(path)


static func load_from_path(path: String) -> FlagManifest:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("FlagManifest path does not exist: %s" % path)
		return null
	var resource: Resource = load(path)
	if resource is FlagManifest:
		return resource as FlagManifest
	push_error("FlagManifest path does not reference a FlagManifest resource: %s" % path)
	return null


func has_declared_flag(flag_name: String) -> bool:
	return flags.has(flag_name)


func has_declared_brace_key(key: String) -> bool:
	return flags.has(key)
