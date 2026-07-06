class_name TagParser
extends RefCounted


const PORTRAIT_TAG_PREFIX := "portrait"


static func extract_tags(dialogue_text: String) -> Dictionary:
	var tags: PackedStringArray = PackedStringArray()
	var errors: PackedStringArray = PackedStringArray()
	var regex: RegEx = RegEx.new()
	regex.compile("(?:^|\\s)(#\\S+)")
	var cleaned_text: String = dialogue_text
	var matches: Array[RegExMatch] = regex.search_all(dialogue_text)
	for index: int in range(matches.size() - 1, -1, -1):
		var match: RegExMatch = matches[index]
		var tag_token: String = match.get_string().strip_edges()
		var tag_body: String = tag_token.trim_prefix("#")
		if tag_body.begins_with(PORTRAIT_TAG_PREFIX):
			errors.append("#portrait is not supported in v1 (D11.4).")
			continue
		if not _is_supported_tag(tag_body):
			errors.append("Unsupported tag '%s'." % tag_body)
			continue
		tags.insert(0, tag_body)
		cleaned_text = (
			cleaned_text.substr(0, match.get_start()) + cleaned_text.substr(match.get_end())
		)
	return {
		"text": cleaned_text.strip_edges(),
		"tags": tags,
		"errors": errors,
	}


static func build_line_with_tags(
	line_id: String,
	next_id: String,
	speaker_id: String,
	dialogue_text: String,
	source_line_number: int
) -> Dictionary:
	var extracted: Dictionary = extract_tags(dialogue_text)
	return CompiledLine.create_line(
		line_id,
		source_line_number,
		next_id,
		speaker_id,
		String(extracted["text"]),
		extracted["tags"]
	)


static func _is_supported_tag(tag_body: String) -> bool:
	if tag_body.begins_with("voice="):
		return tag_body.length() > "voice=".length()
	if tag_body == "time=auto":
		return true
	if tag_body.begins_with("time="):
		var duration_text: String = tag_body.substr("time=".length())
		return duration_text.is_valid_float()
	return false
