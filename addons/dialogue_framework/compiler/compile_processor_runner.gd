extends RefCounted


static func try_create() -> RefCounted:
	var script: Script = DialogueFrameworkProjectSettings.resolve_compile_processor_script()
	if script == null:
		return null
	return script.new() as RefCounted


static func preprocess_line(processor: RefCounted, raw_line: String) -> String:
	if processor == null:
		return raw_line
	if not processor.has_method("_preprocess_line"):
		return raw_line
	return String(processor.call("_preprocess_line", raw_line))


static func post_process_line(processor: RefCounted, line: Dictionary) -> void:
	if processor == null:
		return
	if processor.has_method("_post_process_line"):
		processor.call("_post_process_line", line)
