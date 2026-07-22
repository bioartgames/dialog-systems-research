class_name DialoguePresentationTheme
extends Resource


## Visual identity tokens for dialogue Presentation (ADR-015 D21.2).
## Appearance only — timing and behavior belong on DialoguePresentationPolicy.

@export_group("Speaker")
## Font size applied to the speaker label slot.
@export_range(8, 96, 1, "or_greater", "suffix:px") var speaker_font_size: int = 20
## Font color applied to the speaker label slot.
@export var speaker_color: Color = Color(0.9, 0.82, 0.48, 1.0)

@export_group("Line")
## Default text color for the line [RichTextLabel] slot.
@export var line_color: Color = Color(0.95, 0.96, 0.98, 1.0)
## Minimum height of the line text control.
@export_range(0.0, 400.0, 1.0, "or_greater", "suffix:px") var line_min_height: float = 56.0

@export_group("Line panel")
## Background fill for the line [PanelContainer] when [member DialoguePanelSlot.apply_line_panel_chrome] is [code]true[/code].
@export var panel_bg_color: Color = Color(0.05, 0.06, 0.09, 0.88)
## Corner radius for the line panel [StyleBoxFlat].
@export_range(0, 64, 1, "or_greater", "suffix:px") var panel_corner_radius: int = 22
## Content margins for the line panel: [code]x[/code]=left, [code]y[/code]=top, [code]z[/code]=right, [code]w[/code]=bottom.
@export var panel_content_margin: Vector4 = Vector4(22.0, 14.0, 22.0, 14.0)

@export_group("Choices panel")
## Background fill for the choices [PanelContainer] when line-panel chrome is not applied.
@export var choices_panel_bg_color: Color = Color(0, 0, 0, 0)
## Corner radius for the choices panel [StyleBoxFlat].
@export_range(0, 64, 1, "or_greater", "suffix:px") var choices_panel_corner_radius: int = 0
## Content margins for the choices panel: [code]x[/code]=left, [code]y[/code]=top, [code]z[/code]=right, [code]w[/code]=bottom.
@export var choices_panel_content_margin: Vector4 = Vector4(0, 0, 0, 0)

@export_group("Choice chrome")
## Normal background for choice [Button] styleboxes.
@export var choice_normal_bg: Color = Color(0.08, 0.09, 0.12, 0.9)
## Hover background for choice [Button] styleboxes.
@export var choice_hover_bg: Color = Color(0.12, 0.13, 0.18, 0.95)
## Selected / focused background for choice [Button] styleboxes.
@export var choice_selected_bg: Color = Color(0.14, 0.16, 0.22, 0.98)
## Border color for choice [Button] styleboxes.
@export var choice_border_color: Color = Color(0.92, 0.94, 1.0, 0.85)
## Minimum size of each choice button ([code]x[/code]=width, [code]y[/code]=height).
@export var choice_min_size: Vector2 = Vector2(260.0, 44.0)
## Vertical separation between choice buttons in the choices stack.
@export_range(0, 64, 1, "or_greater", "suffix:px") var choice_separation: int = 10
