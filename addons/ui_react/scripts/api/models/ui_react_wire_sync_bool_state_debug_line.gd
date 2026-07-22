## Writes [code]line_prefix + str(bool_state.get_value())[/code] into a [UiStringState] when the bool changes (and once at wire registration). For debug / inspector readouts ([code]docs/WIRING_LAYER.md[/code] §6).
class_name UiReactWireSyncBoolStateDebugLine
extends UiReactWireRule

## Source bool mirrored into the debug string.
@export var bool_state: UiBoolState
## Destination string state written as [code]line_prefix + str(bool)[/code].
@export var target_string_state: UiStringState
## Optional prefix prepended before the bool string (e.g. [code]Enabled: [/code]).
@export var line_prefix: String = ""


func apply(_source: Node) -> void:
	if not enabled or target_string_state == null:
		return
	var suffix := "—"
	if bool_state != null:
		suffix = str(bool_state.get_value())
	target_string_state.set_value(line_prefix + suffix)
