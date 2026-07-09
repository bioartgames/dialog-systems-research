class_name DialoguePresentationResourceApplier
extends RefCounted


static func resolve_policy(policy: DialoguePresentationPolicy) -> DialoguePresentationPolicy:
	return policy if policy != null else DialoguePresentationPolicy.new()


static func resolve_theme(
	theme: DialoguePresentationTheme,
	policy: DialoguePresentationPolicy
) -> DialoguePresentationTheme:
	var active_policy := resolve_policy(policy)
	if active_policy.reduced_motion and active_policy.accessibility_theme != null:
		return active_policy.accessibility_theme
	return theme if theme != null else DialoguePresentationTheme.new()


static func typewriter_delay(policy: DialoguePresentationPolicy) -> float:
	var active_policy := resolve_policy(policy)
	if active_policy.reduced_motion and active_policy.skip_typewriter_when_reduced_motion:
		return 0.0
	return active_policy.typewriter_char_delay


static func resolve_time_tag(
	policy: DialoguePresentationPolicy,
	tags: PackedStringArray,
	visible_text: String,
	strip_bbcode: Callable
) -> float:
	var active_policy := resolve_policy(policy)
	if not active_policy.interpret_time_tags:
		return 0.0
	for tag: String in tags:
		if tag == "time=auto":
			var plain_text: String = strip_bbcode.call(visible_text)
			return clampf(
				float(plain_text.length()) * active_policy.time_auto_chars_per_sec,
				active_policy.time_auto_min_seconds,
				active_policy.time_auto_max_seconds
			)
		if tag.begins_with("time="):
			var duration_text: String = tag.substr("time=".length())
			if duration_text.is_valid_float():
				return float(duration_text)
	return 0.0


static func find_voice_path(
	policy: DialoguePresentationPolicy,
	tags: PackedStringArray
) -> String:
	if not resolve_policy(policy).interpret_voice_tags:
		return ""
	for tag: String in tags:
		if tag.begins_with("voice="):
			return tag.substr("voice=".length())
	return ""


static func apply_line_overflow(
	policy: DialoguePresentationPolicy,
	line_text: RichTextLabel
) -> void:
	if line_text == null:
		return
	match resolve_policy(policy).line_overflow_mode:
		DialoguePresentationPolicy.TextOverflowMode.GROW:
			line_text.fit_content = true
			line_text.scroll_active = false
			line_text.scroll_following = false
			line_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		DialoguePresentationPolicy.TextOverflowMode.CLAMP:
			line_text.fit_content = false
			line_text.scroll_active = false
			line_text.scroll_following = false
			line_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		DialoguePresentationPolicy.TextOverflowMode.SCROLL:
			line_text.fit_content = false
			line_text.scroll_active = true
			line_text.scroll_following = true
			line_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func build_choice_styles(
	theme: DialoguePresentationTheme
) -> Dictionary:
	var active_theme := theme if theme != null else DialoguePresentationTheme.new()
	return {
		"normal": _make_choice_style(active_theme.choice_normal_bg, Color.TRANSPARENT, 0.0),
		"hover": _make_choice_style(active_theme.choice_hover_bg, Color.TRANSPARENT, 0.0),
		"selected": _make_choice_style(
			active_theme.choice_selected_bg,
			active_theme.choice_border_color,
			2.0
		),
	}


static func apply_native_line_theme(
	theme: DialoguePresentationTheme,
	speaker_label: Label,
	line_text: RichTextLabel,
	line_panel: PanelContainer,
	choices_stack: VBoxContainer,
	policy: DialoguePresentationPolicy
) -> void:
	var active_theme := resolve_theme(theme, policy)
	if speaker_label != null:
		speaker_label.add_theme_color_override("font_color", active_theme.speaker_color)
		speaker_label.add_theme_font_size_override("font_size", active_theme.speaker_font_size)
	if line_text != null:
		line_text.add_theme_color_override("default_color", active_theme.line_color)
		line_text.custom_minimum_size.y = active_theme.line_min_height
		apply_line_overflow(policy, line_text)
	if line_panel != null:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = active_theme.panel_bg_color
		panel_style.set_corner_radius_all(active_theme.panel_corner_radius)
		panel_style.content_margin_left = active_theme.panel_content_margin.x
		panel_style.content_margin_top = active_theme.panel_content_margin.y
		panel_style.content_margin_right = active_theme.panel_content_margin.z
		panel_style.content_margin_bottom = active_theme.panel_content_margin.w
		line_panel.add_theme_stylebox_override("panel", panel_style)
	if choices_stack != null:
		choices_stack.add_theme_constant_override("separation", active_theme.choice_separation)


static func _make_choice_style(bg: Color, border: Color, border_width: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(18)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	if border_width > 0.0:
		style.set_border_width_all(int(border_width))
		style.border_color = border
	return style
