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
## Seconds between typewriter graphemes. [code]0[/code] reveals the line instantly.
## Larger values slow the reveal; ignored when [member skip_typewriter_when_reduced_motion] and [member reduced_motion] apply.
@export_range(0.0, 1.0, 0.001, "or_greater", "suffix:s") var typewriter_char_delay: float = 0.03
## When [code]true[/code], skip typewriter delay while [member reduced_motion] is enabled.
## Does not change [member typewriter_char_delay] itself.
@export var skip_typewriter_when_reduced_motion: bool = true

@export_group("Tags")
## When [code]true[/code], interpret [code]voice=[/code] tags on compiled lines for voice playback.
## When [code]false[/code], voice tags are ignored.
@export var interpret_voice_tags: bool = true
## When [code]true[/code], interpret [code]time=[/code] / [code]time=auto[/code] tags for hold duration.
## When [code]false[/code], time tags produce no hold.
@export var interpret_time_tags: bool = true
## Seconds per character for [code]time=auto[/code] holds: [code]plain_length * this[/code], then clamped.
## Misnamed historically as chars/sec; this is seconds per character.
@export_range(0.0, 1.0, 0.001, "or_greater", "suffix:s") var time_auto_seconds_per_char: float = 0.02
## Minimum seconds for a [code]time=auto[/code] hold after applying [member time_auto_seconds_per_char].
@export_range(0.0, 60.0, 0.01, "or_greater", "suffix:s") var time_auto_min_seconds: float = 0.5
## Maximum seconds for a [code]time=auto[/code] hold after applying [member time_auto_seconds_per_char].
@export_range(0.0, 120.0, 0.01, "or_greater", "suffix:s") var time_auto_max_seconds: float = 8.0

@export_group("Choices")
## When [code]true[/code], choice navigation wraps from first to last and last to first.
## When [code]false[/code], navigation stops at the ends.
@export var wrap_choice_navigation: bool = true
## Seconds for choices panel intro chrome; [code]0[/code] = instant show (native baseline).
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var choices_intro_duration_sec: float = 0.0
## Seconds to keep the choices region visible during outro before hide/clear; [code]0[/code] = instant (native baseline).
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var choices_dismiss_duration_sec: float = 0.0

@export_group("Line panel")
## Seconds for line panel outro on presenter dismiss; [code]0[/code] = instant hide (native baseline).
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:s") var line_dismiss_duration_sec: float = 0.0

@export_group("Text overflow")
## How line text behaves when it exceeds the panel height.
## [enum TextOverflowMode.GROW]: expand control height ([member RichTextLabel.fit_content] on, scroll off).
## [enum TextOverflowMode.CLAMP]: fixed height, clip overflow (scroll off).
## [enum TextOverflowMode.SCROLL]: enable scroll and follow.
@export var line_overflow_mode: TextOverflowMode = TextOverflowMode.CLAMP

@export_group("Accessibility")
## When [code]true[/code], motion durations resolve to [code]0[/code] and typewriter may skip per [member skip_typewriter_when_reduced_motion].
## Prefer pairing with [member accessibility_theme] for high-contrast / large-text tokens.
@export var reduced_motion: bool = false
## Optional theme override applied while accessibility presentation is active.
## When [code]null[/code], the presenter's primary [member DialoguePresenter.theme] is used.
@export var accessibility_theme: DialoguePresentationTheme
