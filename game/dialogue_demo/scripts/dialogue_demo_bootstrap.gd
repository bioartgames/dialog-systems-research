extends Node

const DEMO_DLG_PATH: String = "res://game/dialogue_demo/demo.dlg"
const DEMO_ENTRY: String = "start"
const _DemoGameContext := preload("res://game/dialogue_demo/scripts/demo_game_context.gd")

@onready var _presenter: IDialoguePresenter = $DialogueHUD/Presenter

var _context: GameContext


func _ready() -> void:
	_context = _DemoGameContext.new()
	ConversationController.conversation_ended.connect(_on_conversation_ended)
	ConversationController.conversation_cancelled.connect(_on_conversation_cancelled)
	var compiled: CompiledDialogue = _compile_demo_dialogue()
	if compiled == null:
		return
	ConversationController.start(compiled, DEMO_ENTRY, _context, _presenter)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	var phase: ConversationPhase.Phase = ConversationController.get_debug_state()["phase"]
	if phase == ConversationPhase.Phase.AwaitingInput:
		ConversationController.advance()


func _compile_demo_dialogue() -> CompiledDialogue:
	var file: FileAccess = FileAccess.open(DEMO_DLG_PATH, FileAccess.READ)
	if file == null:
		push_error("Dialogue demo bootstrap could not open %s." % DEMO_DLG_PATH)
		return null
	var source_text: String = file.get_as_text()
	file.close()
	var result: Dictionary = DialogueCompiler.compile_string(source_text, DEMO_DLG_PATH)
	var errors: PackedStringArray = result.get("errors", PackedStringArray())
	if not errors.is_empty():
		push_error("Dialogue demo compile errors: %s" % ", ".join(errors))
		return null
	return result["compiled"] as CompiledDialogue


func _on_conversation_ended(_compiled: CompiledDialogue) -> void:
	_presenter.dismiss()


func _on_conversation_cancelled() -> void:
	_presenter.dismiss()
