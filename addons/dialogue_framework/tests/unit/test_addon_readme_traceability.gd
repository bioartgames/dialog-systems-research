extends GutTest


const README_PATH := "res://addons/dialogue_framework/README.md"
const ARCH_ROOT := "docs/architecture/dialogue/"


func test_readme_exists_in_addon_root() -> void:
	assert_true(FileAccess.file_exists(README_PATH))


func test_readme_links_to_architecture_docs_and_adrs() -> void:
	var text: String = FileAccess.get_file_as_string(README_PATH)
	assert_true(text.contains(ARCH_ROOT + "00-project-goals.md"))
	assert_true(text.contains(ARCH_ROOT + "01-architecture-overview.md"))
	assert_true(text.contains(ARCH_ROOT + "decisions/001-philosophy-and-scope.md"))
	assert_true(text.contains(ARCH_ROOT + "decisions/002-runtime-architecture.md"))


func test_readme_documents_autoload_and_project_settings() -> void:
	var text: String = FileAccess.get_file_as_string(README_PATH)
	assert_true(text.contains("ConversationController"))
	assert_true(text.contains("dialogue_framework/flag_manifest_path"))
	assert_true(text.contains("dialogue_framework/command_manifest_path"))
	assert_true(text.contains("dialogue_framework/compile_processor_path"))


func test_readme_documents_integration_contracts() -> void:
	var text: String = FileAccess.get_file_as_string(README_PATH)
	assert_true(text.contains("GameContext"))
	assert_true(text.contains("IDialoguePresenter"))
	assert_true(text.contains("docs/game_presenter.md"))
