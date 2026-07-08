extends SceneTree

const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/scenarios/showcase.dlg"


func _init() -> void:
	var load_result: Dictionary = ShowcaseDialogueLoader.load_imported(SHOWCASE_DLG_PATH)
	if load_result["compiled"] == null:
		print("SMOKE_FAIL load")
		quit(1)
		return
	var context: GameContext = load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()
	var presenter: IDialoguePresenter = load(
		"res://addons/dialogue_framework/tests/helpers/mock_dialogue_presenter.gd"
	).new()
	root.add_child(presenter as Node)
	if not ConversationController.start(load_result["compiled"], "start", context, presenter):
		print("SMOKE_FAIL start")
		quit(1)
		return
	ConversationController.notify_presentation_finished()
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingInput:
		print("SMOKE_FAIL awaiting_input")
		ConversationController.cancel()
		quit(1)
		return
	ConversationController.advance()
	ConversationController.cancel()
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		print("SMOKE_FAIL idle")
		quit(1)
		return
	print("SMOKE_PASS")
	quit(0)
	return
