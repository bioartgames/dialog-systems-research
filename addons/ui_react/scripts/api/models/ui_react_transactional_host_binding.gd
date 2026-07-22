@tool
## Cohort binding for [UiReactButton] / [UiReactTextureButton]: which [UiTransactionalGroup] this button serves, optional [UiTransactionalScreenConfig] (shared with the paired Apply/Cancel button), and Apply vs Cancel role.
## Assign one instance per button; use the **same** [member screen] subresource on Apply and Cancel when they share [method UiTransactionalGroup.begin_edit_all] timing ([UiReactTransactionalSession]).
class_name UiReactTransactionalHostBinding
extends Resource

## Ordinals match [enum UiReactTransactionalSession.Role].
enum HostRole { NONE = 0, APPLY_ALL = 1, CANCEL_ALL = 2 }

## [UiTransactionalGroup] this host button participates in (Apply/Cancel cohort).
@export var group: UiTransactionalGroup
## Shared [UiTransactionalScreenConfig] for begin-on-ready timing; use the same subresource on Apply and Cancel.
@export var screen: UiTransactionalScreenConfig
## Host role: [enum HostRole.NONE], [enum HostRole.APPLY_ALL], or [enum HostRole.CANCEL_ALL].
@export var role: HostRole = HostRole.NONE
