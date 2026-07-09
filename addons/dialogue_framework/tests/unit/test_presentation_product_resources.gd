extends GutTest


func test_dialogue_presentation_theme_is_resource_with_visual_tokens() -> void:
	var theme := DialoguePresentationTheme.new()
	assert_true(theme is Resource)
	assert_eq(theme.speaker_font_size, 20)
	assert_eq(theme.choice_separation, 10)


func test_dialogue_presentation_input_defines_dialogue_ux_actions() -> void:
	var input := DialoguePresentationInput.new()
	assert_true(input is Resource)
	assert_eq(input.skip_typewriter_action, &"ui_accept")
	assert_eq(input.advance_line_action, &"ui_accept")
	assert_eq(input.navigate_choice_up_action, &"ui_up")
	assert_eq(input.confirm_choice_action, &"ui_accept")


func test_choices_right_layout_preserves_slot_convention() -> void:
	var scene: PackedScene = load(
		"res://addons/dialogue_framework/presentation/native_dialogue_hud_choices_right.tscn"
	)
	var hud: CanvasLayer = scene.instantiate()
	add_child_autofree(hud)
	assert_not_null(hud.get_node_or_null("HudRoot/LinePanel/VBox/SpeakerLabel"))
	assert_not_null(hud.get_node_or_null("HudRoot/LinePanel/VBox/LineText"))
	assert_not_null(hud.get_node_or_null("HudRoot/ChoicesPanel/ChoicesStack"))
	assert_not_null(hud.get_node_or_null("LayoutResources"))
	var presenter: IDialoguePresenter = hud.get_node("Presenter") as IDialoguePresenter
	assert_not_null(presenter)
