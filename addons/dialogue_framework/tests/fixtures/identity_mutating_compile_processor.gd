extends RefCounted


func _post_process_line(line: Dictionary) -> void:
	if not TranslationIdentityValidator.is_localized_surface(line):
		return
	line[CompiledLine.KEY_TRANSLATION_KEY] = "mutated_identity"
