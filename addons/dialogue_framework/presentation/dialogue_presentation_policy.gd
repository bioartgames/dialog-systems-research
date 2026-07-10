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
## Seconds for choices panel intro chrome; 0 = instant show (native baseline).
@export var choices_intro_duration_sec: float = 0.0
## Seconds to keep the choices region visible during outro before hide/clear; 0 = instant (native baseline).
@export var choices_dismiss_duration_sec: float = 0.0

@export_group("Line panel")
## Seconds for line panel outro on presenter dismiss; 0 = instant hide (native baseline).
@export var line_dismiss_duration_sec: float = 0.0

@export_group("Text overflow")
@export var line_overflow_mode: TextOverflowMode = TextOverflowMode.CLAMP

@export_group("Accessibility")
@export var reduced_motion: bool = false
@export var accessibility_theme: DialoguePresentationTheme
