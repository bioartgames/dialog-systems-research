class_name ShowcaseTranslationCatalog
extends RefCounted


const CATALOG_DIR: String = "res://game/dialogue_demo/translations/"
const DEFAULT_LOCALES := ["en", "ja", "fr"]


static func catalog_path(locale: String) -> String:
	return CATALOG_DIR.path_join("showcase.%s.json" % locale)


static func register_locale(locale: String) -> bool:
	var path: String = catalog_path(locale)
	if not FileAccess.file_exists(path):
		push_error("Showcase translation catalog missing: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open showcase translation catalog: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid showcase translation catalog JSON: %s" % path)
		return false
	var data: Dictionary = parsed
	var translation := Translation.new()
	translation.locale = locale
	var messages: Dictionary = data.get("messages", {})
	for key: Variant in messages.keys():
		translation.add_message(String(key), String(messages[key]))
	var speakers: Dictionary = data.get("speakers", {})
	for speaker_id: Variant in speakers.keys():
		translation.add_message(String(speaker_id), String(speakers[speaker_id]), "speakers")
	TranslationServer.add_translation(translation)
	return true


static func register_default_locales() -> bool:
	var all_ok: bool = true
	for locale: String in DEFAULT_LOCALES:
		if not register_locale(locale):
			all_ok = false
	return all_ok
