class_name CompiledDialogueLoader
extends RefCounted

## Thin helper to load an imported `.dlg` or a saved `CompiledDialogue` resource
## (ADR-024 / IK-3). Does **not** compile at runtime — Godot import / authored
## CompiledDialogue remain the source of truth.


## True when `dlg_path.import` exists, is not marked `valid=false`, and lists dest_files.
static func dlg_import_is_valid(dlg_path: String) -> bool:
	var import_path: String = "%s.import" % dlg_path
	if not FileAccess.file_exists(import_path):
		return false
	var text: String = FileAccess.get_file_as_string(import_path)
	if text.contains("valid=false"):
		return false
	return text.contains("dest_files=")


## Load by path. Accepts an imported `.dlg` or a path to a `CompiledDialogue` resource.
## Returns `{ compiled, source, errors }` — `compiled` is set only on success.
##
## Success `source` values: `"imported"` (.dlg via import), `"resource"` (CompiledDialogue path).
## Failure `source` values: `"empty_path"`, `"import_invalid"`, `"missing"`,
## `"wrong_type"`, `"import_load_failed"`.
static func load_compiled(path: String) -> Dictionary:
	var trimmed: String = path.strip_edges()
	if trimmed.is_empty():
		return _failure("empty_path", ["Dialogue path is empty."])

	if _is_dlg_path(trimmed):
		return _load_imported_dlg(trimmed)
	return _load_compiled_resource(trimmed)


## Alias matching ShowcaseDialogueLoader naming (path-parameterized).
static func load_imported(path: String) -> Dictionary:
	return load_compiled(path)


static func _is_dlg_path(path: String) -> bool:
	return path.to_lower().ends_with(".dlg")


static func _load_imported_dlg(dlg_path: String) -> Dictionary:
	if not dlg_import_is_valid(dlg_path):
		return _failure(
			"import_invalid",
			[".dlg import is invalid or missing dest_files for %s" % dlg_path]
		)
	if not ResourceLoader.exists(dlg_path):
		return _failure("missing", ["Dialogue file not found: %s" % dlg_path])
	var resource: Resource = ResourceLoader.load(dlg_path)
	if resource is CompiledDialogue:
		return {
			"compiled": resource as CompiledDialogue,
			"source": "imported",
			"errors": PackedStringArray(),
		}
	return _failure(
		"import_load_failed",
		["load(%s) did not return CompiledDialogue after valid import." % dlg_path]
	)


static func _load_compiled_resource(resource_path: String) -> Dictionary:
	if not ResourceLoader.exists(resource_path):
		return _failure("missing", ["CompiledDialogue resource not found: %s" % resource_path])
	var resource: Resource = ResourceLoader.load(resource_path)
	if resource is CompiledDialogue:
		return {
			"compiled": resource as CompiledDialogue,
			"source": "resource",
			"errors": PackedStringArray(),
		}
	return _failure(
		"wrong_type",
		["load(%s) did not return CompiledDialogue." % resource_path]
	)


static func _failure(source: String, errors: Array[String]) -> Dictionary:
	return {
		"compiled": null,
		"source": source,
		"errors": PackedStringArray(errors),
	}
