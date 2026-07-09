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


func test_dialogue_presentation_policy_defines_behavior_tokens() -> void:
	var policy := DialoguePresentationPolicy.new()
	assert_true(policy is Resource)
	assert_eq(policy.typewriter_char_delay, 0.03)
	assert_true(policy.interpret_voice_tags)
	assert_eq(policy.line_overflow_mode, DialoguePresentationPolicy.TextOverflowMode.CLAMP)


func test_policy_overflow_mode_supports_grow_clamp_scroll() -> void:
	var policy := DialoguePresentationPolicy.new()
	policy.line_overflow_mode = DialoguePresentationPolicy.TextOverflowMode.GROW
	assert_eq(policy.line_overflow_mode, DialoguePresentationPolicy.TextOverflowMode.GROW)
	policy.line_overflow_mode = DialoguePresentationPolicy.TextOverflowMode.CLAMP
	assert_eq(policy.line_overflow_mode, DialoguePresentationPolicy.TextOverflowMode.CLAMP)
	policy.line_overflow_mode = DialoguePresentationPolicy.TextOverflowMode.SCROLL
	assert_eq(policy.line_overflow_mode, DialoguePresentationPolicy.TextOverflowMode.SCROLL)


func test_policy_properties_are_distinct_from_theme() -> void:
	var policy := DialoguePresentationPolicy.new()
	var theme := DialoguePresentationTheme.new()
	var policy_names: Array[String] = _exported_property_names(policy)
	var theme_names: Array[String] = _exported_property_names(theme)
	assert_false("speaker_color" in policy_names)
	assert_false("choice_normal_bg" in policy_names)
	assert_true("line_overflow_mode" in policy_names)
	assert_false("line_overflow_mode" in theme_names)
	assert_true("speaker_color" in theme_names)


func _exported_property_names(obj: Object) -> Array[String]:
	var names: Array[String] = []
	for entry: Dictionary in obj.get_property_list():
		if entry.get("usage", 0) & PROPERTY_USAGE_EDITOR:
			names.append(String(entry["name"]))
	return names


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
