extends GutTest


const WORKFLOW_DOC_PATH := "res://addons/dialogue_framework/docs/external_ide_workflow.md"
const COMPILE_ALL_SCRIPT_PATH := "res://addons/dialogue_framework/tools/compile_all_dlg.gd"


func test_external_ide_workflow_doc_exists() -> void:
	assert_true(FileAccess.file_exists(WORKFLOW_DOC_PATH))


func test_workflow_documents_external_editor_to_reimport_path() -> void:
	var text: String = FileAccess.get_file_as_string(WORKFLOW_DOC_PATH)
	assert_true(text.contains("External text IDE"))
	assert_true(text.contains(".dlg"))
	assert_true(text.contains("reimport") or text.contains("Reimport"))
	assert_true(text.contains("EditorImportPlugin") or text.contains("DlgImportPlugin"))


func test_workflow_documents_no_in_editor_authoring_tooling() -> void:
	var text: String = FileAccess.get_file_as_string(WORKFLOW_DOC_PATH)
	assert_true(text.contains("D18.1"))
	assert_true(text.contains("no visual dialogue editor") or text.contains("No visual"))
	assert_true(text.contains("no in-editor playtest") or text.contains("no in-editor playtest panel"))


func test_workflow_documents_headless_compile_all_ci_command() -> void:
	var text: String = FileAccess.get_file_as_string(WORKFLOW_DOC_PATH)
	assert_true(text.contains("compile_all_dlg.gd"))
	assert_true(text.contains("--strict"))
