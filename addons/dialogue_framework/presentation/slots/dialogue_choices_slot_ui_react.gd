class_name DialogueChoicesSlotUiReact
extends DialogueChoicesSlot

@export var choice_selected_state: UiIntState
@export var choice_button_scene: PackedScene
@export var confirm_sfx_player_path: NodePath


func create_choice_button() -> Button:
	if choice_button_scene != null:
		var instance: Node = choice_button_scene.instantiate()
		var button := instance as Button
		if button != null:
			return button
		push_warning(
			"DialogueChoicesSlotUiReact: choice_button_scene root is not a Button; using Button.new()"
		)
		instance.queue_free()
	return super.create_choice_button()


func set_selected_choice_index(row_index: int) -> void:
	if choice_selected_state != null:
		choice_selected_state.set_value(row_index)


func play_confirm_sfx() -> void:
	if confirm_sfx_player_path.is_empty():
		return
	var player: AudioStreamPlayer = get_node_or_null(confirm_sfx_player_path) as AudioStreamPlayer
	if player != null:
		player.play()
