@tool
class_name DialogueFrameworkProjectSettings


const FLAG_MANIFEST_PATH := "flag_manifest_path"
const COMMAND_MANIFEST_PATH := "command_manifest_path"

const SETTINGS_PREFIX := "dialogue_framework/"

static var SETTINGS_CONFIGURATION: Dictionary = {
	FLAG_MANIFEST_PATH: {
		"value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
	},
	COMMAND_MANIFEST_PATH: {
		"value": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
	},
}


static func setting_name(key: String) -> String:
	return SETTINGS_PREFIX + key


static func register_settings() -> void:
	for key: String in SETTINGS_CONFIGURATION:
		var setting_config: Dictionary = SETTINGS_CONFIGURATION[key]
		var full_name: String = setting_name(key)
		if not ProjectSettings.has_setting(full_name):
			ProjectSettings.set_setting(full_name, setting_config.value)
		ProjectSettings.set_initial_value(full_name, setting_config.value)
		ProjectSettings.add_property_info({
			"name": full_name,
			"type": setting_config.type,
			"hint": setting_config.get("hint", PROPERTY_HINT_NONE),
			"hint_string": setting_config.get("hint_string", ""),
		})
		ProjectSettings.set_as_basic(full_name, true)


static func get_flag_manifest_path() -> String:
	return _get_path(FLAG_MANIFEST_PATH)


static func get_command_manifest_path() -> String:
	return _get_path(COMMAND_MANIFEST_PATH)


static func _get_path(key: String) -> String:
	var full_name: String = setting_name(key)
	if ProjectSettings.has_setting(full_name):
		return String(ProjectSettings.get_setting(full_name))
	return String(SETTINGS_CONFIGURATION[key].value)
