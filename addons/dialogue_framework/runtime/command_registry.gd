class_name CommandRegistry
extends RefCounted


static var _handlers: Dictionary = {}


static func register(command_name: String, handler: Callable) -> void:
	if command_name.is_empty():
		push_error("CommandRegistry.register() requires a command name.")
		return
	if handler == null or not handler.is_valid():
		push_error("CommandRegistry.register() requires a valid handler for '%s'." % command_name)
		return
	if _handlers.has(command_name):
		push_error("Command '%s' is already registered." % command_name)
		return
	_handlers[command_name] = handler


static func dispatch(command_name: String, args: PackedStringArray) -> void:
	if not _handlers.has(command_name):
		push_error("CommandRegistry.dispatch() unknown command '%s'." % command_name)
		return
	await _handlers[command_name].bind(args).call()


static func has_command(command_name: String) -> bool:
	return _handlers.has(command_name)


static func clear_for_tests() -> void:
	_handlers.clear()
