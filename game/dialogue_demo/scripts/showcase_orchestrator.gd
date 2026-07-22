extends Node

## Dialogue demo orchestrator (ADR-024 IK-7).
## Start/context/command wiring uses Integration kit ConversationStarter + CommandBridge.
## Panel UI, smoke harness, locale toggle, and snapshot I/O remain demo-owned.
## Translation JSON catalogs remain demo-local (not the product primary i18n story).

const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/scenarios/showcase.dlg"
const SHOWCASE_ENTRY: String = "start"
const SNAPSHOT_SAVE_PATH: String = "user://showcase_dialogue_snapshot.json"

const _ShowcaseGameContext := preload("res://game/dialogue_demo/scripts/showcase_game_context.gd")
const _ConversationStarter := preload(
	"res://addons/dialogue_framework/integration/conversation_starter.gd"
)
const _CommandBridge := preload(
	"res://addons/dialogue_framework/integration/command_bridge.gd"
)
const _CompiledDialogueLoader := preload(
	"res://addons/dialogue_framework/integration/compiled_dialogue_loader.gd"
)

## When [code]true[/code], defers [method verify_import] after ready (logs [code].dlg[/code] import validity). Demo-only.
@export var auto_verify_import_on_ready: bool = true

@onready var _presenter: DialoguePresenter = $DialogueHUD/Presenter
@onready var _panel: Control = $ShowcaseUI/Panel

var _context: ShowcaseGameContext
var _starter: Node
var _saved_snapshot: DialogueSnapshot = null
var _locale_is_japanese: bool = false


func _ready() -> void:
	_context = _ShowcaseGameContext.new()
	TranslationServer.set_locale("en")
	if not ShowcaseTranslationCatalog.register_default_locales():
		push_error("ShowcaseTranslationCatalog failed to register one or more locale files.")
	_setup_conversation_starter()
	_connect_panel()
	if not ConversationController.command_executed.is_connected(_on_command_executed):
		ConversationController.command_executed.connect(_on_command_executed)
	if not ConversationController.conversation_ended.is_connected(_on_conversation_ended):
		ConversationController.conversation_ended.connect(_on_conversation_ended)
	if auto_verify_import_on_ready:
		call_deferred("verify_import")


func _setup_conversation_starter() -> void:
	_starter = _ConversationStarter.new()
	_starter.name = "ConversationStarter"
	_starter.register_commands_on_ready = false
	_starter.dialogue_path = SHOWCASE_DLG_PATH
	_starter.entry_title = SHOWCASE_ENTRY
	_starter.command_bridge = _CommandBridge.new()
	_starter.on_open_shop = _on_open_shop
	_starter.on_cutscene = _on_cutscene
	_starter.on_camera = _on_camera
	_starter.on_anim = _on_anim
	add_child(_starter)
	_starter.set_context(_context)
	_starter.presenter_path = _starter.get_path_to(_presenter)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
			_starter.cancel_conversation()
			_panel_log("Conversation ended.")


func start_showcase() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_panel_log("Finish or cancel the current conversation first.")
		return
	_starter.entry_title = SHOWCASE_ENTRY
	_starter.dialogue_path = SHOWCASE_DLG_PATH
	if not _starter.start_conversation():
		_panel.set_status("Could not start conversation.")
		_panel_log("ConversationStarter.start_conversation() returned false.")
		return
	_panel.set_status("Showcase in progress — Accept to advance, Cancel to leave.")


func restart_showcase() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_starter.cancel_conversation()
	_context.reset_for_showcase()
	_saved_snapshot = null
	if FileAccess.file_exists(SNAPSHOT_SAVE_PATH):
		DirAccess.remove_absolute(SNAPSHOT_SAVE_PATH)
	_panel.clear_log()
	start_showcase()


func verify_import() -> void:
	var is_valid: bool = _CompiledDialogueLoader.dlg_import_is_valid(SHOWCASE_DLG_PATH)
	var loaded: bool = ResourceLoader.load(SHOWCASE_DLG_PATH) is CompiledDialogue
	var summary: String = "Import: %s | Loaded: %s" % [
		"valid" if is_valid else "invalid",
		"yes" if loaded else "no",
	]
	_panel.set_import_status(summary)
	_panel_log(summary)
	if not is_valid or not loaded:
		_panel.set_status("Import verification failed — reimport in the editor.")


func save_progress() -> void:
	var debug: Dictionary = ConversationController.get_debug_state()
	if debug["phase"] != ConversationPhase.Phase.AwaitingInput:
		_panel_log("Save progress is only available while waiting to continue a line.")
		return
	var load_result: Dictionary = _CompiledDialogueLoader.load_imported(SHOWCASE_DLG_PATH)
	if load_result["compiled"] == null:
		_panel_log("Could not resolve showcase resource for snapshot.")
		return
	var snapshot := DialogueSnapshot.new()
	snapshot.resource_uid = (load_result["compiled"] as CompiledDialogue).resource_uid
	snapshot.entry_label = SHOWCASE_ENTRY
	snapshot.line_id = String(debug["line_id"])
	_saved_snapshot = snapshot
	var file: FileAccess = FileAccess.open(SNAPSHOT_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot.to_dict()))
		file.close()
	_panel_log("Progress saved.")


func resume_progress() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_panel_log("Cancel the current conversation before resuming.")
		return
	var snapshot: DialogueSnapshot = _saved_snapshot
	if snapshot == null and FileAccess.file_exists(SNAPSHOT_SAVE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT_SAVE_PATH))
		if parsed is Dictionary:
			snapshot = DialogueSnapshot.from_dict(parsed)
	if snapshot == null:
		_panel_log("No saved progress found.")
		return
	ConversationController.resume(snapshot, _context, _presenter)
	_panel.set_status("Resumed from saved progress.")


func run_smoke_test() -> void:
	# Demo-owned smoke harness: drives ConversationController directly for multi-entry checks.
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_panel_log("Smoke test failed: not Idle.")
		return
	var load_result: Dictionary = _CompiledDialogueLoader.load_imported(SHOWCASE_DLG_PATH)
	if load_result["compiled"] == null:
		_panel_log("Smoke test failed: could not load showcase.dlg.")
		return
	var compiled: CompiledDialogue = load_result["compiled"]
	var prior_delay: float = _presenter.policy.typewriter_char_delay
	_presenter.policy.typewriter_char_delay = 0.0

	# Phase A: start entry via kit starter
	_starter.entry_title = SHOWCASE_ENTRY
	if not _starter.start_conversation():
		_presenter.policy.typewriter_char_delay = prior_delay
		_panel_log("Smoke test failed: start() returned false.")
		return
	if not await _wait_for_awaiting_input(60):
		_presenter.policy.typewriter_char_delay = prior_delay
		_starter.cancel_conversation()
		_panel_log("Smoke test failed: Phase A did not reach AwaitingInput.")
		return
	ConversationController.advance()
	_starter.cancel_conversation()
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_presenter.policy.typewriter_char_delay = prior_delay
		_panel_log("Smoke test failed: Phase A did not return to Idle.")
		return

	# Phase B/C: alternate entries still use controller API (demo harness / dual-path).
	TranslationServer.set_locale("en")
	if not ConversationController.start(compiled, "shopkeeper_intro", _context, _presenter):
		_presenter.policy.typewriter_char_delay = prior_delay
		_panel_log("Smoke test failed: shopkeeper_intro start() returned false.")
		return
	if not await _wait_for_awaiting_input(60):
		_presenter.policy.typewriter_char_delay = prior_delay
		ConversationController.cancel()
		_panel_log("Smoke test failed: Phase B did not reach AwaitingInput.")
		return
	var speaker_slot: Node = $DialogueHUD/HudRoot/LinePanel/VBox/SpeakerSlot
	var label_text: String = ""
	if speaker_slot != null and speaker_slot.get("text_state") != null:
		label_text = String(speaker_slot.text_state.value)
	if label_text != "Shopkeeper":
		_presenter.policy.typewriter_char_delay = prior_delay
		ConversationController.cancel()
		_panel_log("Smoke test failed: Phase B speaker label '%s' != Shopkeeper." % label_text)
		return
	ConversationController.cancel()

	TranslationServer.set_locale("ja")
	if not ConversationController.start(compiled, "shopkeeper_intro", _context, _presenter):
		_presenter.policy.typewriter_char_delay = prior_delay
		_panel_log("Smoke test failed: Phase C start() returned false.")
		return
	if not await _wait_for_awaiting_input(60):
		_presenter.policy.typewriter_char_delay = prior_delay
		ConversationController.cancel()
		_panel_log("Smoke test failed: Phase C did not reach AwaitingInput.")
		return
	if speaker_slot != null and speaker_slot.get("text_state") != null:
		label_text = String(speaker_slot.text_state.value)
	if label_text != "店主":
		_presenter.policy.typewriter_char_delay = prior_delay
		ConversationController.cancel()
		TranslationServer.set_locale("en")
		_panel_log("Smoke test failed: Phase C speaker label '%s' != 店主." % label_text)
		return
	ConversationController.cancel()
	TranslationServer.set_locale("en")
	_presenter.policy.typewriter_char_delay = prior_delay
	_panel_log("Smoke test passed: load, start, advance, cancel, shopkeeper speaker EN+JA.")


func toggle_locale() -> void:
	_locale_is_japanese = not _locale_is_japanese
	TranslationServer.set_locale("ja" if _locale_is_japanese else "en")
	_panel_log("Language: %s" % ("日本語" if _locale_is_japanese else "English"))


func _wait_for_awaiting_input(max_frames: int) -> bool:
	var waits_remaining: int = max_frames
	while waits_remaining > 0:
		await get_tree().process_frame
		if ConversationController.get_debug_state()["phase"] == ConversationPhase.Phase.AwaitingInput:
			return true
		waits_remaining -= 1
	return false


func _connect_panel() -> void:
	if _panel.has_signal("showcase_requested"):
		_panel.showcase_requested.connect(start_showcase)
	if _panel.has_signal("restart_requested"):
		_panel.restart_requested.connect(restart_showcase)
	if _panel.has_signal("import_verify_requested"):
		_panel.import_verify_requested.connect(verify_import)
	if _panel.has_signal("smoke_test_requested"):
		_panel.smoke_test_requested.connect(run_smoke_test)
	if _panel.has_signal("save_progress_requested"):
		_panel.save_progress_requested.connect(save_progress)
	if _panel.has_signal("resume_progress_requested"):
		_panel.resume_progress_requested.connect(resume_progress)
	if _panel.has_signal("locale_toggle_requested"):
		_panel.locale_toggle_requested.connect(toggle_locale)


# ADR-009 D10.2: if @open_shop is added to showcase.dlg, this handler MUST call
# ConversationController.cancel() and transition to shop game mode (Pattern 1).
# showcase.dlg does not use @open_shop.
func _on_open_shop(shop_id: String) -> void:
	_panel_log("Opened shop: %s" % shop_id)


func _on_cutscene(args: PackedStringArray) -> void:
	_panel_log("Cutscene: %s" % str(args))
	await get_tree().create_timer(0.35).timeout
	_panel_log("Cutscene finished.")


func _on_camera(args: PackedStringArray) -> void:
	_panel_log("Camera: %s" % str(args))


func _on_anim(args: PackedStringArray) -> void:
	_panel_log("Animation: %s" % str(args))


func _on_command_executed(command_name: String, args: Array) -> void:
	if command_name != "emit" or args.is_empty():
		return
	var payload: String = String(args[0])
	match payload:
		"harbor_bell":
			_panel_log("Signal: harbor_bell")
		"shop_buy", "shop_sell", "shop_talk":
			_panel_log("Shop action: %s" % payload.trim_prefix("shop_"))


func _on_conversation_ended(_compiled: CompiledDialogue) -> void:
	_panel.set_status("Conversation complete.")
	_panel_log("Conversation complete.")


func _panel_log(message: String) -> void:
	if _panel.has_method("log_event"):
		_panel.call("log_event", message)
