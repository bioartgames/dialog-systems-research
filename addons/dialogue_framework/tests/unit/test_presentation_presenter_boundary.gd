extends GutTest


const PRESENTATION_ROOT := "res://addons/dialogue_framework/presentation/"
const ALLOWED_PRESENTER := (
	"res://addons/dialogue_framework/presentation/dialogue_presenter.gd"
)
const FORBIDDEN_PRESENTER_CLASS_NAMES: PackedStringArray = [
	"class_name NativeDialoguePresenter",
	"class_name UiReactDialoguePresenter",
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


func test_presentation_has_single_idialogue_presenter_implementation() -> void:
	var files: Array[String] = []
	_collect_gd_files(PRESENTATION_ROOT, files)
	var hits: Array[String] = []
	for file_path: String in files:
		var text: String = FileAccess.get_file_as_string(file_path)
		if text.contains("extends IDialoguePresenter"):
			if file_path != ALLOWED_PRESENTER:
				hits.append(
					"%s extends IDialoguePresenter but only dialogue_presenter.gd is allowed"
					% file_path
				)
		for marker: String in FORBIDDEN_PRESENTER_CLASS_NAMES:
			if text.contains(marker):
				hits.append("%s contains forbidden marker '%s'" % [file_path, marker])
	assert_true(
		hits.is_empty(),
		"Presentation must have one production presenter:\n" + "\n".join(hits)
	)
