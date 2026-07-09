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


func test_default_reference_input_resource_exists() -> void:
	var input: DialoguePresentationInput = load(
		"res://addons/dialogue_framework/presentation/resources/default_dialogue_input.tres"
	) as DialoguePresentationInput
	assert_not_null(input)
	assert_eq(input.skip_typewriter_action, &"ui_accept")
	assert_eq(input.navigate_choice_down_action, &"ui_down")


func test_default_reference_theme_resource_exists() -> void:
	var theme: DialoguePresentationTheme = load(
		"res://addons/dialogue_framework/presentation/resources/default_dialogue_theme.tres"
	) as DialoguePresentationTheme
	assert_not_null(theme)
	assert_eq(theme.speaker_font_size, 20)
	assert_eq(theme.line_min_height, 56.0)
	assert_eq(theme.choice_min_size, Vector2(260.0, 44.0))
	assert_eq(theme.choice_separation, 10)


func test_default_reference_policy_resource_exists() -> void:
	var policy: DialoguePresentationPolicy = load(
		"res://addons/dialogue_framework/presentation/resources/default_dialogue_policy.tres"
	) as DialoguePresentationPolicy
	assert_not_null(policy)
	assert_eq(policy.typewriter_char_delay, 0.03)
	assert_true(policy.interpret_voice_tags)
	assert_true(policy.interpret_time_tags)
	assert_eq(policy.line_overflow_mode, DialoguePresentationPolicy.TextOverflowMode.CLAMP)


func test_reference_layouts_assign_default_presentation_resources() -> void:
	var scene: PackedScene = load(
		"res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn"
	)
	var hud: CanvasLayer = scene.instantiate()
	add_child_autofree(hud)
	var presenter: NativeDialoguePresenter = hud.get_node("Presenter") as NativeDialoguePresenter
	assert_not_null(presenter.theme)
	assert_not_null(presenter.policy)
	assert_not_null(presenter.input)
	assert_true(presenter.theme is DialoguePresentationTheme)
	assert_true(presenter.policy is DialoguePresentationPolicy)
	assert_true(presenter.input is DialoguePresentationInput)


func test_high_contrast_theme_resource_exists_with_focus_tokens() -> void:
	var theme: DialoguePresentationTheme = load(
		"res://addons/dialogue_framework/presentation/resources/default_dialogue_theme_high_contrast.tres"
	) as DialoguePresentationTheme
	assert_not_null(theme)
	assert_eq(theme.speaker_color, Color(1, 0.95, 0.2, 1))
	assert_eq(theme.choice_border_color, Color(1, 0.95, 0.2, 1))
	assert_ne(theme.choice_selected_bg, theme.choice_normal_bg)


func test_large_text_theme_resource_exists_with_scaled_tokens() -> void:
	var theme: DialoguePresentationTheme = load(
		"res://addons/dialogue_framework/presentation/resources/default_dialogue_theme_large_text.tres"
	) as DialoguePresentationTheme
	assert_not_null(theme)
	assert_gt(theme.speaker_font_size, 20)
	assert_gt(theme.line_min_height, 56.0)
	assert_gt(theme.choice_min_size.y, 44.0)


func test_reduced_motion_policy_resource_exists_with_accessibility_theme() -> void:
	var policy: DialoguePresentationPolicy = load(
		"res://addons/dialogue_framework/presentation/resources/default_dialogue_policy_reduced_motion.tres"
	) as DialoguePresentationPolicy
	assert_not_null(policy)
	assert_true(policy.reduced_motion)
	assert_true(policy.skip_typewriter_when_reduced_motion)
	assert_not_null(policy.accessibility_theme)
	assert_true(policy.accessibility_theme is DialoguePresentationTheme)
