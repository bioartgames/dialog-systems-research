class_name DialoguePresentationPolicy
extends Resource


## Behavior and timing for dialogue Presentation (ADR-015 D21.2).
## Appearance belongs on DialoguePresentationTheme; input bindings on DialoguePresentationInput.

enum TextOverflowMode {
	GROW,
	CLAMP,
	SCROLL,
}

@export_group("Typewriter")
@export var typewriter_char_delay: float = 0.03
@export var skip_typewriter_when_reduced_motion: bool = true

@export_group("Tags")
@export var interpret_voice_tags: bool = true
@export var interpret_time_tags: bool = true
@export var time_auto_chars_per_sec: float = 0.02
@export var time_auto_min_seconds: float = 0.5
@export var time_auto_max_seconds: float = 8.0

@export_group("Choices")
@export var wrap_choice_navigation: bool = true

@export_group("Text overflow")
@export var line_overflow_mode: TextOverflowMode = TextOverflowMode.CLAMP

@export_group("Accessibility")
@export var reduced_motion: bool = false
@export var accessibility_theme: DialoguePresentationTheme
