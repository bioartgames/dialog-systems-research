extends SceneTree

const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/scenarios/showcase.dlg"
const CONTROLLER_PATH: String = "res://addons/dialogue_framework/runtime/conversation_controller.gd"
const SHOP_WELCOME_KEY: String = "showcase_shop_welcome"
const CHOICE_BUY_KEY: String = "res://game/dialogue_demo/scenarios/showcase.dlg::70"
const _CompiledDialogueLoader := preload(
	"res://addons/dialogue_framework/integration/compiled_dialogue_loader.gd"
)

var _controller: Node


func _init() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	TranslationServer.set_locale("en")
	var en_shop_welcome: String = String(TranslationServer.translate(SHOP_WELCOME_KEY))
	var en_choice_buy: String = String(TranslationServer.translate(CHOICE_BUY_KEY))
	TranslationServer.set_locale("ja")
	var ja_shop_welcome: String = String(TranslationServer.translate(SHOP_WELCOME_KEY))
	var ja_choice_buy: String = String(TranslationServer.translate(CHOICE_BUY_KEY))
	TranslationServer.set_locale("en")
	if en_shop_welcome.is_empty() or en_shop_welcome == SHOP_WELCOME_KEY:
		print("SMOKE_FAIL catalog_en_shop")
		quit(1)
		return
	if ja_shop_welcome.is_empty() or ja_shop_welcome == SHOP_WELCOME_KEY or ja_shop_welcome == en_shop_welcome:
		print("SMOKE_FAIL catalog_ja_shop")
		quit(1)
		return
	if en_choice_buy.is_empty() or en_choice_buy == CHOICE_BUY_KEY:
		print("SMOKE_FAIL catalog_en_choice")
		quit(1)
		return
	if ja_choice_buy.is_empty() or ja_choice_buy == CHOICE_BUY_KEY or ja_choice_buy == en_choice_buy:
		print("SMOKE_FAIL catalog_ja_choice")
		quit(1)
		return

	_controller = load(CONTROLLER_PATH).new()
	root.add_child(_controller)

	var load_result: Dictionary = _CompiledDialogueLoader.load_imported(SHOWCASE_DLG_PATH)
	if load_result["compiled"] == null:
		print("SMOKE_FAIL load")
		quit(1)
		return
	var compiled: CompiledDialogue = load_result["compiled"]
	var context: GameContext = load("res://addons/dialogue_framework/tests/helpers/mock_game_context.gd").new()
	var presenter: IDialoguePresenter = load(
		"res://addons/dialogue_framework/tests/helpers/mock_dialogue_presenter.gd"
	).new()
	root.add_child(presenter as Node)

	# Phase A: start entry
	if not _controller.start(compiled, "start", context, presenter):
		print("SMOKE_FAIL start")
		quit(1)
		return
	_controller.notify_presentation_finished()
	if _controller.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingInput:
		print("SMOKE_FAIL awaiting_input")
		_controller.cancel()
		quit(1)
		return
	_controller.advance()
	_controller.cancel()
	if _controller.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		print("SMOKE_FAIL idle")
		quit(1)
		return

	# Phase B: shopkeeper_intro EN speaker
	TranslationServer.set_locale("en")
	if not _controller.start(compiled, "shopkeeper_intro", context, presenter):
		print("SMOKE_FAIL shopkeeper_start")
		quit(1)
		return
	_controller.notify_presentation_finished()
	if _controller.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingInput:
		print("SMOKE_FAIL shopkeeper_awaiting")
		_controller.cancel()
		quit(1)
		return
	if presenter.last_step.speaker_id != "Shopkeeper":
		print("SMOKE_FAIL shopkeeper_speaker")
		_controller.cancel()
		quit(1)
		return
	_controller.cancel()
	if _controller.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		print("SMOKE_FAIL shopkeeper_idle")
		quit(1)
		return

	# Phase C: shopkeeper_intro JA line text
	TranslationServer.set_locale("ja")
	if not _controller.start(compiled, "shopkeeper_intro", context, presenter):
		print("SMOKE_FAIL ja_start")
		quit(1)
		return
	_controller.notify_presentation_finished()
	if _controller.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingInput:
		print("SMOKE_FAIL ja_awaiting")
		_controller.cancel()
		quit(1)
		return
	if presenter.last_step.text != ja_shop_welcome:
		print("SMOKE_FAIL ja_text")
		_controller.cancel()
		quit(1)
		return
	_controller.cancel()
	TranslationServer.set_locale("en")

	# Phase D: shopkeeper CHOICE localization + AwaitingChoice locale refresh
	if not _controller.start(compiled, "shopkeeper_intro", context, presenter):
		print("SMOKE_FAIL choice_start")
		quit(1)
		return
	_controller.notify_presentation_finished()
	_controller.advance()
	if _controller.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingChoice:
		print("SMOKE_FAIL choice_awaiting")
		_controller.cancel()
		quit(1)
		return
	if presenter.last_step.options[0]["text"] != en_choice_buy:
		print("SMOKE_FAIL choice_en_text")
		_controller.cancel()
		quit(1)
		return
	var choice_line_id: String = String(presenter.last_step.line_id)
	var choice_target: String = String(presenter.last_step.options[0]["target_line_id"])
	var choice_index: int = int(presenter.last_step.options[0]["index"])
	var calls_before_refresh: int = presenter.present_call_count
	TranslationServer.set_locale("ja")
	if presenter.present_call_count <= calls_before_refresh:
		print("SMOKE_FAIL choice_refresh_present")
		_controller.cancel()
		quit(1)
		return
	if presenter.last_step.options[0]["text"] != ja_choice_buy:
		print("SMOKE_FAIL choice_ja_text")
		_controller.cancel()
		quit(1)
		return
	if _controller.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingChoice:
		print("SMOKE_FAIL choice_phase_after_refresh")
		_controller.cancel()
		quit(1)
		return
	if String(presenter.last_step.line_id) != choice_line_id:
		print("SMOKE_FAIL choice_line_id_changed")
		_controller.cancel()
		quit(1)
		return
	if String(presenter.last_step.options[0]["target_line_id"]) != choice_target:
		print("SMOKE_FAIL choice_target_changed")
		_controller.cancel()
		quit(1)
		return
	if int(presenter.last_step.options[0]["index"]) != choice_index:
		print("SMOKE_FAIL choice_index_changed")
		_controller.cancel()
		quit(1)
		return
	_controller.cancel()
	TranslationServer.set_locale("en")
	print("SMOKE_PASS")
	quit(0)
