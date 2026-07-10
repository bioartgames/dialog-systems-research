extends GutTest


func test_format_and_compiler_version_constants() -> void:
	assert_eq(DialogueFrameworkVersions.FORMAT_VERSION, 1)
	assert_eq(DialogueFrameworkVersions.COMPILER_VERSION, 2)


func test_plugin_cfg_uses_semver() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load("res://addons/dialogue_framework/plugin.cfg")
	assert_eq(err, OK)
	var version: String = config.get_value("plugin", "version", "")
	var semver := RegEx.new()
	semver.compile("^\\d+\\.\\d+\\.\\d+$")
	assert_not_null(semver.search(version), "plugin.cfg version should follow semver: %s" % version)
