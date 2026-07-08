extends RefCounted


func _preprocess_line(raw: String) -> String:
	return raw.replace("Hi.", "Hello.")


func _post_process_line(line: Dictionary) -> void:
	if CompiledLine.get_kind(line) == LineKind.Kind.LINE:
		line[CompiledLine.KEY_SPEAKER_ID] = "post_processed"
