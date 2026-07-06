class_name EndStepBuilder
extends RefCounted


static func build(line_id: String) -> ConversationStep:
	return ConversationStep.create_end(line_id)
