class_name DialogueCompiler
extends RefCounted

const _COMPILE_PROCESSOR_RUNNER := preload("res://addons/dialogue_framework/compiler/compile_processor_runner.gd")

static func compile(
	source_text: String,
	source_path: String,
	strict: bool = false
) -> Dictionary:
	var validation_mode: CompileManifestLoader.ValidationMode = (
		CompileManifestLoader.ValidationMode.STRICT
		if strict
		else CompileManifestLoader.ValidationMode.EDITOR_IMPORT
	)
	var manifest_result: Dictionary = CompileManifestLoader.load_for_compile(validation_mode)
	var errors: PackedStringArray = manifest_result.get("errors", PackedStringArray()).duplicate()
	var warnings: PackedStringArray = manifest_result.get("warnings", PackedStringArray()).duplicate()

	if strict and not errors.is_empty():
		return _failed_compile(errors, warnings)

	var processor: RefCounted = _COMPILE_PROCESSOR_RUNNER.try_create()
	var graph_result: Dictionary = FlatGraphBuilder.build(
		source_text,
		source_path,
		manifest_result.get("flag_manifest"),
		manifest_result.get("command_manifest"),
		strict,
		processor
	)
	errors.append_array(graph_result.get("errors", PackedStringArray()))
	warnings.append_array(graph_result.get("warnings", PackedStringArray()))
	if not errors.is_empty():
		return _failed_compile(errors, warnings)

	var compiled: CompiledDialogue = CompiledDialogue.new()
	compiled.resource_uid = ResourceUidGenerator.resolve(source_path)
	compiled.source_path = source_path
	compiled.raw_text = source_text
	compiled.format_version = DialogueFrameworkVersions.FORMAT_VERSION
	compiled.compiler_version = DialogueFrameworkVersions.COMPILER_VERSION
	compiled.titles = graph_result.get("titles", {})
	compiled.lines = graph_result.get("lines", {})
	compiled.first_title = String(graph_result.get("first_title", ""))
	return {
		"compiled": compiled,
		"errors": errors,
		"warnings": warnings,
	}


## Dev/test compile API (D5.7). Production runtime loads imported `.tres` only (D1.3).
static func compile_string(source_text: String, source_path: String = "", strict: bool = false) -> Dictionary:
	return compile(source_text, source_path, strict)


static func _failed_compile(
	errors: PackedStringArray,
	warnings: PackedStringArray
) -> Dictionary:
	return {
		"compiled": null,
		"errors": errors,
		"warnings": warnings,
	}
