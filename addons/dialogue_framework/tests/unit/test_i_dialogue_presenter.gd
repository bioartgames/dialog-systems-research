extends GutTest


class MockPresenter extends IDialoguePresenter:
	var last_step: ConversationStep = null
	var dismiss_called: bool = false

	func present(step: ConversationStep) -> void:
		last_step = step

	func dismiss() -> void:
		dismiss_called = true


func test_presenter_interface_defines_present_and_dismiss_only() -> void:
	var script: Script = IDialoguePresenter
	var method_names: PackedStringArray = PackedStringArray()
	for method: Dictionary in script.get_script_method_list():
		var name: String = String(method.get("name"))
		if not name.begins_with("_"):
			method_names.append(name)
	method_names.sort()
	assert_eq(method_names, PackedStringArray(["dismiss", "present"]))


func test_mock_presenter_can_present_and_dismiss() -> void:
	var presenter := MockPresenter.new()
	add_child_autofree(presenter)
	var step := ConversationStep.create_line("l1", "Roll", "Hi")
	presenter.present(step)
	assert_eq(presenter.last_step, step)
	presenter.dismiss()
	assert_true(presenter.dismiss_called)
