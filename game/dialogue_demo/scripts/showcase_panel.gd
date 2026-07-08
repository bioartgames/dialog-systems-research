extends Control

signal showcase_requested
signal restart_requested
signal import_verify_requested
signal smoke_test_requested
signal save_progress_requested
signal resume_progress_requested
signal locale_toggle_requested


@onready var _status: Label = $Margin/VBox/Status
@onready var _import_status: Label = $Margin/VBox/ImportStatus
@onready var _log: RichTextLabel = $Margin/VBox/Log


func _ready() -> void:
	_log.scroll_following = true
	clear_log()


func clear_log() -> void:
	_log.clear()
	_log.append_text("[b]Dialogue Framework Showcase[/b]\n")
	set_status("Press Interactive Showcase to begin.")


func set_status(text: String) -> void:
	_status.text = text


func set_import_status(text: String) -> void:
	_import_status.text = text


func log_event(message: String) -> void:
	var stamp: String = Time.get_time_string_from_system()
	_log.append_text("[%s] %s\n" % [stamp, message])


func _on_showcase_pressed() -> void:
	showcase_requested.emit()


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_import_verify_pressed() -> void:
	import_verify_requested.emit()


func _on_smoke_test_pressed() -> void:
	smoke_test_requested.emit()


func _on_save_progress_pressed() -> void:
	save_progress_requested.emit()


func _on_resume_progress_pressed() -> void:
	resume_progress_requested.emit()


func _on_locale_pressed() -> void:
	locale_toggle_requested.emit()
