extends GutTest


const SAVE_PATH := "user://gut_compiled_dialogue_test.tres"


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func test_top_level_fields_and_defaults() -> void:
	var dialogue := CompiledDialogue.new()
	dialogue.resource_uid = "uid_roll"
	dialogue.source_path = "res://npcs/roll.dlg"
	dialogue.raw_text = "~ start"
	dialogue.titles = {"start": "line_start"}
	dialogue.lines = {"line_start": CompiledLine.create_title("line_start", 1, "", "start")}
	dialogue.first_title = "start"

	assert_eq(dialogue.format_version, DialogueFrameworkVersions.FORMAT_VERSION)
	assert_eq(dialogue.compiler_version, DialogueFrameworkVersions.COMPILER_VERSION)
	assert_true(dialogue.has_line("line_start"))
	assert_eq(dialogue.get_title_line_id("start"), "line_start")


func test_serializes_to_tres() -> void:
	var dialogue := CompiledDialogue.new()
	dialogue.resource_uid = "uid_test"
	dialogue.source_path = "res://npcs/roll.dlg"
	dialogue.raw_text = "~ start"
	dialogue.titles = {"start": "line_start"}
	dialogue.lines = {"line_start": CompiledLine.create_title("line_start", 1, "", "start")}
	dialogue.first_title = "start"

	var err: Error = ResourceSaver.save(dialogue, SAVE_PATH)
	assert_eq(err, OK)

	var loaded: CompiledDialogue = load(SAVE_PATH) as CompiledDialogue
	assert_not_null(loaded)
	assert_eq(loaded.resource_uid, "uid_test")
	assert_eq(loaded.titles, {"start": "line_start"})
