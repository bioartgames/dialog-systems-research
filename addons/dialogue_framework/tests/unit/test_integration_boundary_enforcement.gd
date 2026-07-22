extends GutTest


## IK-0 / ADR-024 D30.2 — Integration package dependency purity.
## Scans .gd sources only. README and non-script assets are ignored.


const RUNTIME_ROOT := "res://addons/dialogue_framework/runtime/"
const COMPILER_ROOT := "res://addons/dialogue_framework/compiler/"
const DATA_ROOT := "res://addons/dialogue_framework/data/"
const INTEGRATION_ROOT := "res://addons/dialogue_framework/integration/"
const PRESENTATION_MARKER := "res://addons/dialogue_framework/presentation/"
const INTEGRATION_MARKER := "res://addons/dialogue_framework/integration/"
const UIREACT_MARKER := "res://addons/ui_react/"
const UIREACT_CLASS_MARKERS: PackedStringArray = [
	"res://addons/ui_react/",
	"UiStringState",
	"UiBoolState",
	"UiIntState",
	"UiArrayState",
	"UiReactLabel",
	"UiReactRichTextLabel",
	"UiReactLineEdit",
	"UiReactControl",
]


func _collect_gd_files(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = dir.get_next()
			continue
		var full_path: String = dir_path.path_join(entry_name)
		if dir.current_is_dir():
			_collect_gd_files(full_path, out)
		elif entry_name.ends_with(".gd"):
			out.append(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()


func _find_forbidden_markers(
	root_path: String,
	marker: String,
	label: String
) -> Array[String]:
	var hits: Array[String] = []
	var files: Array[String] = []
	_collect_gd_files(root_path, files)
	for file_path: String in files:
		var text: String = FileAccess.get_file_as_string(file_path)
		if text.contains(marker):
			hits.append("%s: %s contains '%s'" % [label, file_path, marker])
	return hits


func test_integration_directory_exists() -> void:
	assert_true(
		DirAccess.dir_exists_absolute(INTEGRATION_ROOT),
		"Missing Integration kit directory: %s" % INTEGRATION_ROOT
	)


func test_runtime_compiler_data_do_not_reference_integration() -> void:
	var hits: Array[String] = []
	hits.append_array(
		_find_forbidden_markers(RUNTIME_ROOT, INTEGRATION_MARKER, "runtime")
	)
	hits.append_array(
		_find_forbidden_markers(COMPILER_ROOT, INTEGRATION_MARKER, "compiler")
	)
	hits.append_array(
		_find_forbidden_markers(DATA_ROOT, INTEGRATION_MARKER, "data")
	)
	assert_true(
		hits.is_empty(),
		"Forbidden integration references found:\n" + "\n".join(hits)
	)


func test_integration_does_not_reference_presentation() -> void:
	var hits: Array[String] = _find_forbidden_markers(
		INTEGRATION_ROOT,
		PRESENTATION_MARKER,
		"integration"
	)
	assert_true(
		hits.is_empty(),
		"Forbidden presentation references found in integration:\n" + "\n".join(hits)
	)


func test_integration_does_not_reference_ui_react() -> void:
	var hits: Array[String] = _find_forbidden_markers(
		INTEGRATION_ROOT,
		UIREACT_MARKER,
		"integration"
	)
	var files: Array[String] = []
	_collect_gd_files(INTEGRATION_ROOT, files)
	for file_path: String in files:
		var text: String = FileAccess.get_file_as_string(file_path)
		for marker: String in UIREACT_CLASS_MARKERS:
			if text.contains(marker):
				hits.append("%s contains forbidden marker '%s'" % [file_path, marker])
	assert_true(
		hits.is_empty(),
		"Forbidden UiReact references found in integration:\n" + "\n".join(hits)
	)
