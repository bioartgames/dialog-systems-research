@tool
## One inspector row for controller rumble: [b]when[/b] ([member trigger] or [member state_watch]) and engine [method Input.start_joy_vibration] params.
## Spec: [code]docs/FEEDBACK_LAYER.md[/code].
class_name UiReactHapticFeedbackTarget
extends Resource

## When [code]false[/code], this feedback row is ignored at dispatch time.
@export var enabled: bool = true

## When set, this row runs from [signal UiBoolState.value_changed] and [method UiReactFeedbackTargetHelper.sync_initial_state] only — [member trigger] is ignored at runtime. Dispatch semantics: [code]docs/FEEDBACK_LAYER.md[/code] §9.
@export var state_watch: UiBoolState

## Used only when [member state_watch] is [code]null[/code]. Reuses [enum UiAnimTarget.Trigger] ([code]docs/FEEDBACK_LAYER.md[/code]).
@export var trigger: UiAnimTarget.Trigger = UiAnimTarget.Trigger.PRESSED

## Use [code]-1[/code] for first connected joypad ([method Input.get_connected_joypads]); otherwise silent no-op when none.
@export var device_id: int = -1

## Weak motor magnitude for [method Input.start_joy_vibration] ([code]0[/code]–[code]1[/code]).
@export_range(0.0, 1.0, 0.01) var weak_magnitude: float = 0.5
## Strong motor magnitude for [method Input.start_joy_vibration] ([code]0[/code]–[code]1[/code]).
@export_range(0.0, 1.0, 0.01) var strong_magnitude: float = 0.5
## Duration passed to [method Input.start_joy_vibration] (seconds). Must be [code]> 0[/code] for a valid row.
@export_range(0.001, 5.0, 0.001, "or_greater", "suffix:s") var duration_sec: float = 0.08
