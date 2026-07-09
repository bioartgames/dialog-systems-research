extends GutTest


const RUNTIME_ROOT := "res://addons/dialogue_framework/runtime/"
const COMPILER_ROOT := "res://addons/dialogue_framework/compiler/"
const DATA_ROOT := "res://addons/dialogue_framework/data/"
const PRESENTATION_MARKER := "res://addons/dialogue_framework/presentation/"
const UIREACT_MARKER := "res://addons/ui_react/"
const SLOTS_ROOT := "res://addons/dialogue_framework/presentation/slots/"
const DIALOGUE_PRESENTER_PATH := (
	"res://addons/dialogue_framework/presentation/dialogue_presenter.gd"
)
const UIREACT_CLASS_MARKERS: PackedStringArray = [
	"res://addons/ui_react/",
	"UiStringState",
	"UiBoolState",
	"UiIntState",
	"UiArrayState",
	"UiReactLabel",
	"UiReactRichTextLabel",
	"UiReactDialoguePresenter",
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


func _is_native_slot_script(file_path: String) -> bool:
	if not file_path.begins_with(SLOTS_ROOT):
		return false
	if file_path.contains("_ui_react"):
		return false
	return file_path.get_file().begins_with("dialogue_") and file_path.ends_with("_slot.gd")


func test_runtime_compiler_data_do_not_reference_presentation() -> void:
	var hits: Array[String] = []
	hits.append_array(
		_find_forbidden_markers(RUNTIME_ROOT, PRESENTATION_MARKER, "runtime")
	)
	hits.append_array(
		_find_forbidden_markers(COMPILER_ROOT, PRESENTATION_MARKER, "compiler")
	)
	hits.append_array(
		_find_forbidden_markers(DATA_ROOT, PRESENTATION_MARKER, "data")
	)
	assert_true(
		hits.is_empty(),
		"Forbidden presentation references found:\n" + "\n".join(hits)
	)


func test_runtime_does_not_reference_ui_react() -> void:
	var hits: Array[String] = _find_forbidden_markers(
		RUNTIME_ROOT,
		UIREACT_MARKER,
		"runtime"
	)
	assert_true(
		hits.is_empty(),
		"Forbidden UiReact references found in runtime:\n" + "\n".join(hits)
	)


func test_dialogue_presenter_does_not_depend_on_ui_react() -> void:
	var text: String = FileAccess.get_file_as_string(DIALOGUE_PRESENTER_PATH)
	var hits: Array[String] = []
	for marker: String in UIREACT_CLASS_MARKERS:
		if text.contains(marker):
			hits.append(
				"dialogue_presenter.gd contains forbidden marker '%s'" % marker
			)
	assert_true(
		hits.is_empty(),
		"DialoguePresenter must not depend on UiReact:\n" + "\n".join(hits)
	)


func test_native_slot_scripts_do_not_depend_on_ui_react() -> void:
	var files: Array[String] = []
	_collect_gd_files(SLOTS_ROOT, files)
	var hits: Array[String] = []
	for file_path: String in files:
		if not _is_native_slot_script(file_path):
			continue
		var text: String = FileAccess.get_file_as_string(file_path)
		for marker: String in UIREACT_CLASS_MARKERS:
			if text.contains(marker):
				hits.append("%s contains forbidden marker '%s'" % [file_path, marker])
	assert_true(
		hits.is_empty(),
		"Native slot scripts must not depend on UiReact:\n" + "\n".join(hits)
	)
