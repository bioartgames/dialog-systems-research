@tool
## One inspector row for audio feedback: [b]when[/b] ([member trigger] or [member state_watch]) and [b]what[/b] ([member player]).
## Spec: [code]docs/FEEDBACK_LAYER.md[/code].
class_name UiReactAudioFeedbackTarget
extends Resource

## When [code]false[/code], this feedback row is ignored at dispatch time.
@export var enabled: bool = true

## When set, this row runs from [signal UiBoolState.value_changed] and [method UiReactFeedbackTargetHelper.sync_initial_state] only — [member trigger] is ignored at runtime. Dispatch semantics: [code]docs/FEEDBACK_LAYER.md[/code] §9.
@export var state_watch: UiBoolState

## Used only when [member state_watch] is [code]null[/code]. Reuses [enum UiAnimTarget.Trigger] ([code]docs/FEEDBACK_LAYER.md[/code]).
@export var trigger: UiAnimTarget.Trigger = UiAnimTarget.Trigger.PRESSED

## [AudioStreamPlayer] that plays when this row fires. Empty path is a no-op.
@export_node_path("AudioStreamPlayer") var player: NodePath = NodePath()
