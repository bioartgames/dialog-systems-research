extends GutTest


const NATIVE_HUD := "res://addons/dialogue_framework/presentation/native_dialogue_hud.tscn"
const UIREACT_HUD := "res://addons/dialogue_framework/presentation/ui_react_dialogue_hud.tscn"


func test_native_presenter_applies_theme_to_speaker_label() -> void:
	var scene: PackedScene = load(NATIVE_HUD)
	var hud: CanvasLayer = scene.instantiate()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var custom_theme := DialoguePresentationTheme.new()
	custom_theme.speaker_color = Color(0.2, 0.4, 0.9, 1.0)
	custom_theme.speaker_font_size = 28
	presenter.theme = custom_theme
	presenter.policy = DialoguePresentationPolicy.new()
	add_child_autofree(hud)
	await get_tree().process_frame
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	assert_eq(speaker_label.get_theme_color("font_color"), custom_theme.speaker_color)
	assert_eq(speaker_label.get_theme_font_size("font_size"), 28)


func test_native_line_panel_keeps_line_banner_after_configure() -> void:
	var scene: PackedScene = load(NATIVE_HUD)
	var hud: CanvasLayer = scene.instantiate()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var custom_theme := DialoguePresentationTheme.new()
	custom_theme.panel_bg_color = Color(0.2, 0.4, 0.9, 1.0)
	presenter.theme = custom_theme
	presenter.policy = DialoguePresentationPolicy.new()
	add_child_autofree(hud)
	await get_tree().process_frame
	var line_panel: PanelContainer = hud.get_node("HudRoot/LinePanel") as PanelContainer
	var panel_style: StyleBoxFlat = line_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(panel_style)
	assert_eq(panel_style.bg_color, custom_theme.panel_bg_color)


func test_native_presenter_uses_policy_typewriter_delay() -> void:
	var presenter: DialoguePresenter = autofree(DialoguePresenter.new())
	var active_policy := DialoguePresentationPolicy.new()
	active_policy.typewriter_char_delay = 0.12
	presenter.policy = active_policy
	assert_eq(DialoguePresentationResourceApplier.typewriter_delay(presenter.policy), 0.12)


func test_native_presenter_policy_reduced_motion_skips_typewriter() -> void:
	var presenter: DialoguePresenter = autofree(DialoguePresenter.new())
	var active_policy := DialoguePresentationPolicy.new()
	active_policy.reduced_motion = true
	active_policy.skip_typewriter_when_reduced_motion = true
	active_policy.typewriter_char_delay = 0.25
	presenter.policy = active_policy
	assert_eq(DialoguePresentationResourceApplier.typewriter_delay(presenter.policy), 0.0)


func test_native_presenter_applies_policy_line_overflow_mode() -> void:
	var scene: PackedScene = load(NATIVE_HUD)
	var hud: CanvasLayer = scene.instantiate()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy = DialoguePresentationPolicy.new()
	presenter.policy.line_overflow_mode = DialoguePresentationPolicy.TextOverflowMode.SCROLL
	add_child_autofree(hud)
	await get_tree().process_frame
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	assert_true(line_text.scroll_active)
	assert_false(line_text.fit_content)


func test_native_presenter_applies_grow_and_clamp_overflow_modes() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var policy := DialoguePresentationPolicy.new()
	policy.line_overflow_mode = DialoguePresentationPolicy.TextOverflowMode.GROW
	DialoguePresentationResourceApplier.apply_line_overflow(policy, line_text)
	assert_true(line_text.fit_content)
	assert_false(line_text.scroll_active)
	policy.line_overflow_mode = DialoguePresentationPolicy.TextOverflowMode.CLAMP
	DialoguePresentationResourceApplier.apply_line_overflow(policy, line_text)
	assert_false(line_text.fit_content)
	assert_false(line_text.scroll_active)


func test_apply_line_overflow_sets_after_shaping_for_typewriter() -> void:
	var line_text: RichTextLabel = autofree(RichTextLabel.new())
	var policy := DialoguePresentationPolicy.new()
	DialoguePresentationResourceApplier.apply_line_overflow(policy, line_text)
	assert_eq(
		line_text.visible_characters_behavior,
		TextServer.VC_CHARS_AFTER_SHAPING
	)


func test_uireact_presenter_applies_policy_line_overflow_mode() -> void:
	if not ResourceLoader.exists(UIREACT_HUD):
		pending("Ui React HUD scene unavailable")
		return
	var scene: PackedScene = load(UIREACT_HUD)
	var hud: CanvasLayer = scene.instantiate()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	presenter.policy = DialoguePresentationPolicy.new()
	presenter.policy.line_overflow_mode = DialoguePresentationPolicy.TextOverflowMode.SCROLL
	add_child_autofree(hud)
	await get_tree().process_frame
	var line_text: RichTextLabel = hud.get_node("HudRoot/LinePanel/VBox/LineText") as RichTextLabel
	assert_true(line_text.scroll_active)
	assert_false(line_text.fit_content)


func test_uireact_layout_includes_wired_input_listener() -> void:
	if not ResourceLoader.exists(UIREACT_HUD):
		pending("Ui React HUD scene unavailable")
		return
	var scene: PackedScene = load(UIREACT_HUD)
	var hud: CanvasLayer = scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var listener: DialoguePresentationInputListener = hud.get_node("InputListener") as DialoguePresentationInputListener
	assert_not_null(listener)
	assert_true(listener.listening_enabled)
	assert_not_null(listener.input)
	assert_eq(listener.presenter, NodePath("../Presenter"))


func test_native_layout_includes_wired_input_listener() -> void:
	var scene: PackedScene = load(NATIVE_HUD)
	var hud: CanvasLayer = scene.instantiate()
	add_child_autofree(hud)
	await get_tree().process_frame
	var listener: DialoguePresentationInputListener = hud.get_node("InputListener") as DialoguePresentationInputListener
	assert_not_null(listener)
	assert_true(listener.listening_enabled)
	assert_not_null(listener.input)
	assert_eq(listener.presenter, NodePath("../Presenter"))


func test_uireact_presenter_builds_choice_styles_from_theme() -> void:
	if not ResourceLoader.exists(UIREACT_HUD):
		pending("Ui React HUD scene unavailable")
		return
	var scene: PackedScene = load(UIREACT_HUD)
	var hud: CanvasLayer = scene.instantiate()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var custom_theme := DialoguePresentationTheme.new()
	custom_theme.choice_normal_bg = Color(0.1, 0.2, 0.3, 1.0)
	presenter.theme = custom_theme
	presenter.policy = DialoguePresentationPolicy.new()
	add_child_autofree(hud)
	await get_tree().process_frame
	var styles: Dictionary = DialoguePresentationResourceApplier.build_choice_styles(custom_theme)
	assert_eq(styles["normal"].bg_color, custom_theme.choice_normal_bg)


func test_uireact_presenter_uses_shared_policy_tag_resolution() -> void:
	var presenter: DialoguePresenter = autofree(DialoguePresenter.new())
	var active_policy := DialoguePresentationPolicy.new()
	active_policy.interpret_voice_tags = false
	presenter.policy = active_policy
	var tags := PackedStringArray(["voice=res://missing.ogg"])
	assert_eq(DialoguePresentationResourceApplier.find_voice_path(presenter.policy, tags), "")


func test_policy_reduced_motion_skips_time_tags() -> void:
	var active_policy := DialoguePresentationPolicy.new()
	active_policy.reduced_motion = true
	active_policy.interpret_time_tags = true
	var tags := PackedStringArray(["time=2.5"])
	var delay: float = DialoguePresentationResourceApplier.resolve_time_tag(
		active_policy,
		tags,
		"Hello world",
		Callable(self, "_strip_bbcode_for_test")
	)
	assert_eq(delay, 0.0)


func test_policy_reduced_motion_selects_accessibility_theme() -> void:
	var base_theme := DialoguePresentationTheme.new()
	base_theme.speaker_color = Color(0.1, 0.1, 0.1, 1.0)
	var a11y_theme := DialoguePresentationTheme.new()
	a11y_theme.speaker_color = Color(1, 0, 0, 1.0)
	var active_policy := DialoguePresentationPolicy.new()
	active_policy.reduced_motion = true
	active_policy.accessibility_theme = a11y_theme
	var resolved: DialoguePresentationTheme = DialoguePresentationResourceApplier.resolve_theme(
		base_theme,
		active_policy
	)
	assert_eq(resolved.speaker_color, a11y_theme.speaker_color)


func test_native_presenter_applies_accessibility_theme_when_reduced_motion() -> void:
	var scene: PackedScene = load(NATIVE_HUD)
	var hud: CanvasLayer = scene.instantiate()
	var presenter: DialoguePresenter = hud.get_node("Presenter") as DialoguePresenter
	var base_theme := DialoguePresentationTheme.new()
	base_theme.speaker_color = Color(0.1, 0.2, 0.3, 1.0)
	base_theme.speaker_font_size = 18
	var a11y_theme := DialoguePresentationTheme.new()
	a11y_theme.speaker_color = Color(1, 0.5, 0, 1.0)
	a11y_theme.speaker_font_size = 30
	presenter.theme = base_theme
	presenter.policy = DialoguePresentationPolicy.new()
	presenter.policy.reduced_motion = true
	presenter.policy.accessibility_theme = a11y_theme
	add_child_autofree(hud)
	await get_tree().process_frame
	var speaker_label: Label = hud.get_node("HudRoot/LinePanel/VBox/SpeakerLabel") as Label
	assert_eq(speaker_label.get_theme_color("font_color"), a11y_theme.speaker_color)
	assert_eq(speaker_label.get_theme_font_size("font_size"), 30)


func _strip_bbcode_for_test(text: String) -> String:
	return text.replace("[", "").replace("]", "")
