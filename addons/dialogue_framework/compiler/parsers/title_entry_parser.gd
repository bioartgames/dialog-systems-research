class_name TitleEntryParser
extends RefCounted

const TITLE_PREFIX := "~"


static func matches(text: String) -> bool:
	return text.strip_edges().begins_with(TITLE_PREFIX)


static func parse(text: String, source_line_number: int) -> Dictionary:
	if not matches(text):
		return {}
	var title_name: String = text.strip_edges().substr(TITLE_PREFIX.length()).strip_edges()
	if title_name.is_empty():
		return {}
	return {
		"title_name": title_name,
		"source_line_number": source_line_number,
	}


static func resolve_first_title(ordered_title_names: PackedStringArray) -> String:
	if ordered_title_names.is_empty():
		return ""
	return ordered_title_names[0]


static func build_title_mapping(
	ordered_entries: Array[Dictionary],
	line_ids: PackedStringArray
) -> Dictionary:
	var titles: Dictionary = {}
	var count: int = mini(ordered_entries.size(), line_ids.size())
	for i: int in count:
		var entry: Dictionary = ordered_entries[i]
		if not entry.has("title_name"):
			continue
		titles[entry["title_name"]] = line_ids[i]
	return titles
