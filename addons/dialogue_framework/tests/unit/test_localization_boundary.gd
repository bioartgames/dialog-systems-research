extends GutTest


const RUNTIME_ROOT := "res://addons/dialogue_framework/runtime/"
const PRESENTATION_ROOT := "res://addons/dialogue_framework/presentation/"
const ALLOWED_RUNTIME_TRANSLATION_FILES := ["line_step_builder.gd"]


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


func test_runtime_translation_lookup_isolated_to_step_builders() -> void:
	var files: Array[String] = []
	_collect_gd_files(RUNTIME_ROOT, files)
	var hits: Array[String] = []
	for file_path: String in files:
		var file_name: String = file_path.get_file()
		var text: String = FileAccess.get_file_as_string(file_path)
		if not text.contains("TranslationServer"):
			continue
		if file_name in ALLOWED_RUNTIME_TRANSLATION_FILES:
			continue
		hits.append(file_path)
	assert_true(
		hits.is_empty(),
		"TranslationServer must only appear in step builders:\n" + "\n".join(hits)
	)


func test_presentation_does_not_lookup_translation_catalog_for_authored_text() -> void:
	var files: Array[String] = []
	_collect_gd_files(PRESENTATION_ROOT, files)
	var hits: Array[String] = []
	for file_path: String in files:
		var text: String = FileAccess.get_file_as_string(file_path)
		if text.contains("TranslationServer"):
			hits.append("%s: TranslationServer" % file_path)
		if text.contains("CompiledDialogue"):
			hits.append("%s: CompiledDialogue" % file_path)
	assert_true(
		hits.is_empty(),
		"Presentation must not perform catalog lookup or traverse compiled data:\n"
		+ "\n".join(hits)
	)


func test_dialogue_presenter_resolves_speaker_via_speakers_domain() -> void:
	var presenter_path: String = (
		"res://addons/dialogue_framework/presentation/dialogue_presenter.gd"
	)
	var text: String = FileAccess.get_file_as_string(presenter_path)
	assert_true(text.contains('tr(step.speaker_id, "speakers")'))
