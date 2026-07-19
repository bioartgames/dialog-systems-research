extends Node

const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/scenarios/showcase.dlg"
const SHOWCASE_ENTRY: String = "start"
const SNAPSHOT_SAVE_PATH: String = "user://showcase_dialogue_snapshot.json"
const TRANSLATION_DATA_PATH_TEMPLATE: String = "res://game/dialogue_demo/translations/showcase.%s.json"
const SHOWCASE_LOCALES: Array[String] = ["en", "ja", "fr"]
const LOCALE_LABELS: Dictionary = {
	"en": "English",
	"ja": "日本語",
	"fr": "Français",
}

const _ShowcaseGameContext := preload("res://game/dialogue_demo/scripts/showcase_game_context.gd")
const _ShowcaseCommandHandlers := preload(
	"res://game/dialogue_demo/scripts/showcase_command_handlers.gd"
)

@export var auto_verify_import_on_ready: bool = true

@onready var _presenter: DialoguePresenter = $DialogueHUD/Presenter
@onready var _panel: Control = $ShowcaseUI/Panel

var _context: ShowcaseGameContext
var _commands_registered: bool = false
var _saved_snapshot: DialogueSnapshot = null
var _locale_index: int = 0


func _ready() -> void:
	_context = _ShowcaseGameContext.new()
	TranslationServer.set_locale(SHOWCASE_LOCALES[_locale_index])
	_register_showcase_translations()
	_register_command_handlers()
	_connect_panel()
	if not ConversationController.command_executed.is_connected(_on_command_executed):
		ConversationController.command_executed.connect(_on_command_executed)
	if not ConversationController.conversation_ended.is_connected(_on_conversation_ended):
		ConversationController.conversation_ended.connect(_on_conversation_ended)
	if auto_verify_import_on_ready:
		call_deferred("verify_import")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
			ConversationController.cancel()
			_panel_log("Conversation ended.")


func start_showcase() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_panel_log("Finish or cancel the current conversation first.")
		return
	var load_result: Dictionary = ShowcaseDialogueLoader.load_imported(SHOWCASE_DLG_PATH)
	if load_result["compiled"] == null:
		var errors: PackedStringArray = load_result.get("errors", PackedStringArray())
		_panel.set_status("Could not load showcase dialogue.")
		_panel_log("Load failed: %s" % ", ".join(errors))
		return
	var compiled: CompiledDialogue = load_result["compiled"]
	if not ConversationController.start(compiled, SHOWCASE_ENTRY, _context, _presenter):
		_panel.set_status("Could not start conversation.")
		_panel_log("ConversationController.start() returned false.")
		return
	_panel.set_status("Showcase in progress — Accept to advance, Cancel to leave.")


func restart_showcase() -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		ConversationController.cancel()
	_context.reset_for_showcase()
	_saved_snapshot = null
	_panel.clear_log()
	start_showcase()


func verify_import() -> void:
	var is_valid: bool = ShowcaseDialogueLoader.dlg_import_is_valid(SHOWCASE_DLG_PATH)
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
	var load_result: Dictionary = ShowcaseDialogueLoader.load_imported(SHOWCASE_DLG_PATH)
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
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_panel_log("Smoke test requires Idle phase — cancel first.")
		return
	var load_result: Dictionary = ShowcaseDialogueLoader.load_imported(SHOWCASE_DLG_PATH)
	if load_result["compiled"] == null:
		_panel_log("Smoke test failed: could not load showcase.dlg.")
		return
	if not ConversationController.start(
		load_result["compiled"], SHOWCASE_ENTRY, _context, _presenter
	):
		_panel_log("Smoke test failed: start() returned false.")
		return
	var prior_delay: float = _presenter.policy.typewriter_char_delay
	_presenter.policy.typewriter_char_delay = 0.0
	var waits_remaining: int = 60
	while waits_remaining > 0:
		await get_tree().process_frame
		if ConversationController.get_debug_state()["phase"] == ConversationPhase.Phase.AwaitingInput:
			break
		waits_remaining -= 1
	_presenter.policy.typewriter_char_delay = prior_delay
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.AwaitingInput:
		_panel_log("Smoke test failed: did not reach AwaitingInput.")
		ConversationController.cancel()
		return
	ConversationController.advance()
	ConversationController.cancel()
	_panel_log("Smoke test passed: load, start, advance, cancel.")


func toggle_locale() -> void:
	_locale_index = (_locale_index + 1) % SHOWCASE_LOCALES.size()
	var locale: String = SHOWCASE_LOCALES[_locale_index]
	TranslationServer.set_locale(locale)
	_panel_log("Language: %s" % String(LOCALE_LABELS.get(locale, locale)))


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


func _register_command_handlers() -> void:
	if _commands_registered:
		return
	_ShowcaseCommandHandlers.register_all(
		_context,
		_on_open_shop,
		func(args: PackedStringArray) -> void:
			_panel_log("Cutscene: %s" % str(args))
			await get_tree().create_timer(0.35).timeout
			_panel_log("Cutscene finished."),
		func(args: PackedStringArray) -> void:
			_panel_log("Camera: %s" % str(args)),
		func(args: PackedStringArray) -> void:
			_panel_log("Animation: %s" % str(args))
	)
	_commands_registered = true


func _on_open_shop(shop_id: String) -> void:
	_panel_log("Opened shop: %s" % shop_id)
	ConversationController.cancel()
	_panel.set_status("Shop opened — conversation paused.")


func _on_command_executed(command_name: String, args: Array) -> void:
	if command_name == "emit" and args.size() > 0:
		_panel_log("Signal: %s" % String(args[0]))


func _on_conversation_ended(_compiled: CompiledDialogue) -> void:
	_panel.set_status("Conversation complete.")
	_panel_log("Conversation complete.")


func _register_showcase_translations() -> void:
	for locale: String in SHOWCASE_LOCALES:
		var data: Dictionary = _load_locale_catalog(locale)
		if data.is_empty():
			push_error("Showcase locale catalog missing or invalid for '%s'." % locale)
			continue
		var translation := Translation.new()
		translation.locale = locale
		var messages: Dictionary = data.get("messages", {})
		for key: Variant in messages.keys():
			translation.add_message(String(key), String(messages[key]))
		var speakers: Dictionary = data.get("speakers", {})
		for speaker_id: Variant in speakers.keys():
			translation.add_message(String(speaker_id), String(speakers[speaker_id]), "speakers")
		TranslationServer.add_translation(translation)


func _load_locale_catalog(locale: String) -> Dictionary:
	var catalog_path: String = TRANSLATION_DATA_PATH_TEMPLATE % locale
	if not FileAccess.file_exists(catalog_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
	if parsed is Dictionary:
		return parsed
	return {}


func _panel_log(message: String) -> void:
	if _panel.has_method("log_event"):
		_panel.call("log_event", message)
