class_name CompiledLine


const KEY_ID := &"id"
const KEY_KIND := &"kind"
const KEY_SOURCE_LINE_NUMBER := &"source_line_number"
const KEY_NEXT_ID := &"next_id"

const KEY_NAME := &"name"
const KEY_SPEAKER_ID := &"speaker_id"
const KEY_TEXT := &"text"
const KEY_TAGS := &"tags"
const KEY_TRANSLATION_KEY := &"translation_key"
const KEY_CONDITION_TOKENS := &"condition_tokens"
const KEY_NEXT_SIBLING_ID := &"next_sibling_id"
const KEY_NEXT_ID_AFTER := &"next_id_after"
const KEY_TARGET_LINE_ID := &"target_line_id"
const KEY_COMMAND_NAME := &"command_name"
const KEY_ARGS_TOKENS := &"args_tokens"
const KEY_RESOLVED_TARGET_LINE_ID := &"resolved_target_line_id"

const SHARED_KEYS: PackedStringArray = [
	KEY_ID,
	KEY_KIND,
	KEY_SOURCE_LINE_NUMBER,
	KEY_NEXT_ID,
]

const KIND_SPECIFIC_KEYS: Dictionary = {
	LineKind.Kind.TITLE: [KEY_NAME],
	LineKind.Kind.LINE: [KEY_SPEAKER_ID, KEY_TEXT, KEY_TAGS, KEY_TRANSLATION_KEY],
	LineKind.Kind.CONDITION: [KEY_CONDITION_TOKENS, KEY_NEXT_SIBLING_ID, KEY_NEXT_ID_AFTER],
	LineKind.Kind.CHOICE: [KEY_TEXT, KEY_CONDITION_TOKENS, KEY_TARGET_LINE_ID],
	LineKind.Kind.COMMAND: [KEY_COMMAND_NAME, KEY_ARGS_TOKENS],
	LineKind.Kind.GOTO: [KEY_RESOLVED_TARGET_LINE_ID],
	LineKind.Kind.END: [],
}


static func create_shared(
	line_id: String,
	kind: LineKind.Kind,
	source_line_number: int,
	next_id: String
) -> Dictionary:
	return {
		KEY_ID: line_id,
		KEY_KIND: kind,
		KEY_SOURCE_LINE_NUMBER: source_line_number,
		KEY_NEXT_ID: next_id,
	}


static func create_title(
	line_id: String,
	source_line_number: int,
	next_id: String,
	title_name: String
) -> Dictionary:
	var line: Dictionary = create_shared(line_id, LineKind.Kind.TITLE, source_line_number, next_id)
	line[KEY_NAME] = title_name
	return line


static func create_line(
	line_id: String,
	source_line_number: int,
	next_id: String,
	speaker_id: String,
	text: String,
	tags: PackedStringArray = PackedStringArray(),
	translation_key: String = ""
) -> Dictionary:
	var line: Dictionary = create_shared(line_id, LineKind.Kind.LINE, source_line_number, next_id)
	line[KEY_SPEAKER_ID] = speaker_id
	line[KEY_TEXT] = text
	line[KEY_TAGS] = tags
	line[KEY_TRANSLATION_KEY] = translation_key if translation_key != "" else text
	return line


static func create_condition(
	line_id: String,
	source_line_number: int,
	next_id: String,
	condition_tokens: Array,
	next_sibling_id: String,
	next_id_after: String
) -> Dictionary:
	var line: Dictionary = create_shared(line_id, LineKind.Kind.CONDITION, source_line_number, next_id)
	line[KEY_CONDITION_TOKENS] = condition_tokens
	line[KEY_NEXT_SIBLING_ID] = next_sibling_id
	line[KEY_NEXT_ID_AFTER] = next_id_after
	return line


static func create_choice(
	line_id: String,
	source_line_number: int,
	next_id: String,
	text: String,
	condition_tokens: Array,
	target_line_id: String
) -> Dictionary:
	var line: Dictionary = create_shared(line_id, LineKind.Kind.CHOICE, source_line_number, next_id)
	line[KEY_TEXT] = text
	line[KEY_CONDITION_TOKENS] = condition_tokens
	line[KEY_TARGET_LINE_ID] = target_line_id
	return line


static func create_command(
	line_id: String,
	source_line_number: int,
	next_id: String,
	command_name: String,
	args_tokens: Array
) -> Dictionary:
	var line: Dictionary = create_shared(line_id, LineKind.Kind.COMMAND, source_line_number, next_id)
	line[KEY_COMMAND_NAME] = command_name
	line[KEY_ARGS_TOKENS] = args_tokens
	return line


static func create_goto(
	line_id: String,
	source_line_number: int,
	next_id: String,
	resolved_target_line_id: String
) -> Dictionary:
	var line: Dictionary = create_shared(line_id, LineKind.Kind.GOTO, source_line_number, next_id)
	line[KEY_RESOLVED_TARGET_LINE_ID] = resolved_target_line_id
	return line


static func create_end(line_id: String, source_line_number: int, next_id: String = "") -> Dictionary:
	return create_shared(line_id, LineKind.Kind.END, source_line_number, next_id)


static func get_kind(line: Dictionary) -> LineKind.Kind:
	return line.get(KEY_KIND, -1) as LineKind.Kind


static func validate(line: Dictionary) -> bool:
	if line.is_empty():
		push_error("CompiledLine validation failed: line is empty.")
		return false

	for key: StringName in SHARED_KEYS:
		if not line.has(key):
			push_error("CompiledLine validation failed: missing shared field '%s'." % key)
			return false

	var kind: int = line.get(KEY_KIND, -1)
	if kind < LineKind.Kind.TITLE or kind > LineKind.Kind.END:
		push_error("CompiledLine validation failed: invalid kind %s." % str(kind))
		return false

	var required_keys: Array = KIND_SPECIFIC_KEYS.get(kind, [])
	for key: StringName in required_keys:
		if not line.has(key):
			push_error(
				"CompiledLine validation failed: missing field '%s' for kind %s."
				% [key, LineKind.Kind.keys()[kind]]
			)
			return false

	var allowed_keys: Dictionary = {}
	for key: StringName in SHARED_KEYS:
		allowed_keys[key] = true
	for key: StringName in required_keys:
		allowed_keys[key] = true

	for key: StringName in line.keys():
		if not allowed_keys.has(key):
			push_error("CompiledLine validation failed: unexpected field '%s'." % key)
			return false

	return true
