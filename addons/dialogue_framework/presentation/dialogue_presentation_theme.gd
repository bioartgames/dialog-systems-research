class_name DialoguePresentationTheme
extends Resource


## Visual identity tokens for dialogue Presentation (ADR-015 D21.2).
## Appearance only — timing and behavior belong on DialoguePresentationPolicy.

@export_group("Speaker")
@export var speaker_font_size: int = 20
@export var speaker_color: Color = Color(0.9, 0.82, 0.48, 1.0)

@export_group("Line")
@export var line_color: Color = Color(0.95, 0.96, 0.98, 1.0)
@export var line_min_height: float = 56.0

@export_group("Line panel")
@export var panel_bg_color: Color = Color(0.05, 0.06, 0.09, 0.88)
@export var panel_corner_radius: int = 22
@export var panel_content_margin: Vector4 = Vector4(22.0, 14.0, 22.0, 14.0)

@export_group("Choice chrome")
@export var choice_normal_bg: Color = Color(0.08, 0.09, 0.12, 0.9)
@export var choice_hover_bg: Color = Color(0.12, 0.13, 0.18, 0.95)
@export var choice_selected_bg: Color = Color(0.14, 0.16, 0.22, 0.98)
@export var choice_border_color: Color = Color(0.92, 0.94, 1.0, 0.85)
@export var choice_min_size: Vector2 = Vector2(260.0, 44.0)
@export var choice_separation: int = 10
