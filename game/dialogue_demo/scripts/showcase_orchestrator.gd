extends Node

const SHOWCASE_DLG_PATH: String = "res://game/dialogue_demo/showcase.dlg"
const SECONDARY_DLG_PATH: String = "res://game/dialogue_demo/secondary.dlg"
const ZERO_CHOICES_DLG_PATH: String = "res://game/dialogue_demo/zero_choices.dlg"
const SHOP_INTERRUPT_DLG_PATH: String = "res://game/dialogue_demo/shop_interrupt.dlg"
const SNAPSHOT_SAVE_PATH: String = "user://showcase_dialogue_snapshot.json"
const FLAG_MANIFEST_PATH: String = "res://game/dialogue_demo/resources/flag_manifest.tres"
const COMMAND_MANIFEST_PATH: String = "res://game/dialogue_demo/resources/command_manifest.tres"

const _ShowcaseGameContext := preload("res://game/dialogue_demo/scripts/showcase_game_context.gd")
const _ShowcaseCommandHandlers := preload(
	"res://game/dialogue_demo/scripts/showcase_command_handlers.gd"
)

@export var auto_start_showcase: bool = true

@onready var _presenter: UiReactDialoguePresenter = $DialogueHUD/Presenter
@onready var _qa_panel: Control = $ShowcaseQA/Panel

var _context: ShowcaseGameContext
var _saved_snapshot: DialogueSnapshot = null
var _active_compiled: CompiledDialogue = null
var _active_entry: String = ""
var _conversation_active: bool = false
var _commands_registered: bool = false
var _locale_index: int = 0
var _locales: PackedStringArray = PackedStringArray(["en", "fr"])


func _ready() -> void:
	_configure_showcase_project_settings()
	_context = _ShowcaseGameContext.new()
	_register_showcase_translations()
	_register_command_handlers()
	_connect_controller_signals()
	_connect_qa_buttons()
	if auto_start_showcase:
		call_deferred("start_showcase_conversation")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_try_cancel()
		return
	if not event.is_action_pressed("ui_accept"):
		return
	var phase: ConversationPhase.Phase = ConversationController.get_debug_state()["phase"]
	match phase:
		ConversationPhase.Phase.PresentingLine:
			_presenter.request_skip_typewriter()
		ConversationPhase.Phase.AwaitingInput:
			ConversationController.advance()
		ConversationPhase.Phase.AwaitingChoice:
			ConversationController.choose(_presenter.get_selected_choice_index())


func start_showcase_conversation() -> void:
	_start_conversation(SHOWCASE_DLG_PATH, "showcase")


func start_secondary_conversation() -> void:
	_start_conversation(SECONDARY_DLG_PATH, "merchant")


func start_zero_choices_conversation() -> void:
	_context.set_flag("never_show", false)
	_start_conversation(ZERO_CHOICES_DLG_PATH, "start")


func start_shop_interrupt_conversation() -> void:
	_start_conversation(SHOP_INTERRUPT_DLG_PATH, "start")


func save_snapshot() -> void:
	if not _conversation_active:
		_qa_log("snapshot", "No active conversation to snapshot.")
		return
	var debug: Dictionary = ConversationController.get_debug_state()
	var phase: ConversationPhase.Phase = debug["phase"]
	if phase != ConversationPhase.Phase.AwaitingInput:
		_qa_log("snapshot", "Save snapshot while AwaitingInput (after a line finishes).")
		return
	if _active_compiled == null:
		return
	var snapshot := DialogueSnapshot.new()
	snapshot.resource_uid = _active_compiled.resource_uid
	snapshot.entry_label = _active_entry
	snapshot.line_id = String(debug["line_id"])
	_saved_snapshot = snapshot
	_persist_snapshot_to_disk(snapshot)
	_qa_log(
		"snapshot",
		"Saved line_id=%s resource=%s"
		% [snapshot.line_id, snapshot.resource_uid]
	)


func _persist_snapshot_to_disk(snapshot: DialogueSnapshot) -> void:
	var file: FileAccess = FileAccess.open(SNAPSHOT_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(snapshot.to_dict()))
	file.close()


func resume_snapshot() -> void:
	var snapshot: DialogueSnapshot = _saved_snapshot
	if snapshot == null:
		snapshot = _load_snapshot_from_disk()
	if snapshot == null:
		_qa_log("resume", "No saved snapshot. Use Save Snapshot during AwaitingInput.")
		return
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_qa_log("resume", "Cancel or wait for Idle before resume.")
		return
	_qa_log("resume", "Resuming line_id=%s entry=%s" % [snapshot.line_id, snapshot.entry_label])
	ConversationController.resume(snapshot, _context, _presenter)


func toggle_locale() -> void:
	_locale_index = (_locale_index + 1) % _locales.size()
	var locale: String = _locales[_locale_index]
	TranslationServer.set_locale(locale)
	_qa_log("locale", "Set locale to %s (active LINE re-presents)." % locale)


func toggle_dev_choice() -> void:
	var next: bool = not bool(_context.get_flag("show_dev_choice"))
	_context.set_flag("show_dev_choice", next)
	_qa_log("context", "show_dev_choice=%s" % str(next))


func reset_context() -> void:
	_context.reset_for_showcase()
	_qa_log("context", "GameContext reset.")


func _start_conversation(dlg_path: String, entry: String) -> void:
	if ConversationController.get_debug_state()["phase"] != ConversationPhase.Phase.Idle:
		_qa_log("start", "Conversation already active — cancel first or wait for end.")
		return
	var load_result: Dictionary = _load_compiled_dialogue(dlg_path)
	var compiled: CompiledDialogue = load_result.get("compiled") as CompiledDialogue
	if compiled == null:
		_qa_log("error", "Failed to load %s" % dlg_path)
		return
	_active_compiled = compiled
	_active_entry = entry
	_conversation_active = true
	_qa_log(
		"load",
		"%s via %s (manifests: flag + command)"
		% [dlg_path, String(load_result.get("source", "unknown"))]
	)
	var started: bool = ConversationController.start(compiled, entry, _context, _presenter)
	if started:
		_qa_log("conversation_started", "entry=%s (framework has no conversation_started signal)" % entry)
	else:
		_conversation_active = false
		_qa_log("error", "ConversationController.start() returned false.")


func _load_compiled_dialogue(dlg_path: String) -> Dictionary:
	if ResourceLoader.exists(dlg_path):
		var resource: Resource = load(dlg_path)
		if resource is CompiledDialogue:
			return {"compiled": resource, "source": "imported"}
	var file: FileAccess = FileAccess.open(dlg_path, FileAccess.READ)
	if file == null:
		return {"compiled": null, "source": "missing"}
	var source_text: String = file.get_as_text()
	file.close()
	var result: Dictionary = DialogueCompiler.compile_string(source_text, dlg_path)
	var errors: PackedStringArray = result.get("errors", PackedStringArray())
	if not errors.is_empty():
		push_error("Showcase compile errors for %s: %s" % [dlg_path, ", ".join(errors)])
		return {"compiled": null, "source": "compile_failed"}
	return {"compiled": result["compiled"], "source": "runtime_compile_string"}


func _try_cancel() -> void:
	if ConversationController.get_debug_state()["phase"] == ConversationPhase.Phase.Idle:
		return
	_qa_log("cancel", "ConversationController.cancel()")
	ConversationController.cancel()


func _configure_showcase_project_settings() -> void:
	ProjectSettings.set_setting(
		DialogueFrameworkProjectSettings.setting_name(DialogueFrameworkProjectSettings.FLAG_MANIFEST_PATH),
		FLAG_MANIFEST_PATH
	)
	ProjectSettings.set_setting(
		DialogueFrameworkProjectSettings.setting_name(DialogueFrameworkProjectSettings.COMMAND_MANIFEST_PATH),
		COMMAND_MANIFEST_PATH
	)
	_qa_log("manifests", "Runtime flag + command manifest paths configured for showcase.")


func _register_command_handlers() -> void:
	if _commands_registered:
		return
	_ShowcaseCommandHandlers.register_all(
		_context,
		_on_open_shop,
		_on_cutscene,
		_on_camera,
		_on_anim
	)
	_commands_registered = true


func _on_open_shop(shop_id: String) -> void:
	_qa_log("game_command", "open_shop(%s) — cancelling conversation" % shop_id)
	ConversationController.cancel()


func _on_cutscene(args: PackedStringArray) -> void:
	_qa_log("game_command", "cutscene async %s" % str(args))
	await get_tree().create_timer(0.35).timeout
	_qa_log("game_command", "cutscene finished")


func _on_camera(args: PackedStringArray) -> void:
	_qa_log("game_command", "camera %s" % str(args))


func _on_anim(args: PackedStringArray) -> void:
	_qa_log("game_command", "anim %s" % str(args))


func _connect_controller_signals() -> void:
	ConversationController.step_ready.connect(_on_step_ready)
	ConversationController.command_executed.connect(_on_command_executed)
	ConversationController.conversation_ended.connect(_on_conversation_ended)
	ConversationController.conversation_cancelled.connect(_on_conversation_cancelled)


func _connect_qa_buttons() -> void:
	var buttons: Node = $ShowcaseQA/Panel/Margin/VBox/Buttons
	buttons.get_node("StartShowcase").pressed.connect(start_showcase_conversation)
	buttons.get_node("StartSecondary").pressed.connect(start_secondary_conversation)
	buttons.get_node("ZeroChoices").pressed.connect(start_zero_choices_conversation)
	buttons.get_node("ShopInterrupt").pressed.connect(start_shop_interrupt_conversation)
	buttons.get_node("Cancel").pressed.connect(_try_cancel)
	buttons.get_node("SaveSnapshot").pressed.connect(save_snapshot)
	buttons.get_node("ResumeSnapshot").pressed.connect(resume_snapshot)
	buttons.get_node("ToggleLocale").pressed.connect(toggle_locale)
	buttons.get_node("ToggleDevChoice").pressed.connect(toggle_dev_choice)
	buttons.get_node("ResetContext").pressed.connect(reset_context)
	buttons.get_node("ClearLog").pressed.connect(
		func() -> void:
			if _qa_panel.has_method("clear_log"):
				_qa_panel.call("clear_log")
	)


func _on_step_ready(step: ConversationStep) -> void:
	var debug: Dictionary = ConversationController.get_debug_state()
	if _qa_panel.has_method("log_phase"):
		_qa_panel.call(
			"log_phase",
			debug["phase"],
			String(debug["line_id"]),
			step.kind
		)
	_qa_log("step_ready", "%s line_id=%s" % [step.kind, step.line_id])


func _on_command_executed(command_name: String, args: Array) -> void:
	_qa_log("command_executed", "%s %s" % [command_name, str(args)])


func _on_conversation_ended(compiled: CompiledDialogue) -> void:
	_conversation_active = false
	_presenter.dismiss()
	_qa_log("conversation_ended", compiled.source_path if compiled != null else "")


func _on_conversation_cancelled() -> void:
	_conversation_active = false
	_presenter.dismiss()
	_qa_log("conversation_cancelled", "presenter dismissed")


func _register_showcase_translations() -> void:
	var fr := Translation.new()
	fr.locale = "fr"
	fr.add_message("showcase_welcome", "Bienvenue, {hero_name}. Cette visite couvre le runtime du framework.")
	fr.add_message(
		"showcase_i18n_line",
		"Changez la langue dans le panneau QA pour tester le rafraîchissement de traduction."
	)
	fr.add_message("Roll", "Roule", "speakers")
	TranslationServer.add_translation(fr)


func _qa_log(category: String, message: String) -> void:
	if _qa_panel.has_method("log_event"):
		_qa_panel.call("log_event", category, message)


func _load_snapshot_from_disk() -> DialogueSnapshot:
	if not FileAccess.file_exists(SNAPSHOT_SAVE_PATH):
		return null
	var file: FileAccess = FileAccess.open(SNAPSHOT_SAVE_PATH, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return DialogueSnapshot.from_dict(parsed as Dictionary)
	return null
