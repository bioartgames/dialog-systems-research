extends SceneTree


const CompileAllDlgRunner := preload("res://addons/dialogue_framework/tools/compile_all_dlg_runner.gd")

const EXIT_SUCCESS := 0
const EXIT_COMPILE_FAILURE := 1
const EXIT_USAGE_ERROR := 2


func _init() -> void:
	var user_args: PackedStringArray = PackedStringArray(OS.get_cmdline_user_args())
	if user_args.has("--help") or user_args.has("-h"):
		_print_usage()
		quit(EXIT_SUCCESS)
		return
	var strict: bool = user_args.has("--strict")
	var result: Dictionary = CompileAllDlgRunner.run(strict)
	for warning_message: String in result.get("warnings", PackedStringArray()):
		push_warning(warning_message)
	var errors: PackedStringArray = result.get("errors", PackedStringArray())
	for error_message: String in errors:
		push_error(error_message)
	var compiled_count: int = int(result.get("compiled_count", 0))
	var dlg_file_count: int = int(result.get("dlg_file_count", 0))
	if errors.is_empty():
		print(
			"Dialogue compile-all: %d/%d .dlg file(s) compiled successfully (strict=%s)."
			% [compiled_count, dlg_file_count, str(strict)]
		)
		quit(EXIT_SUCCESS)
		return
	print(
		"Dialogue compile-all failed: %d error(s) across %d .dlg file(s) (strict=%s)."
		% [errors.size(), dlg_file_count, str(strict)]
	)
	quit(EXIT_COMPILE_FAILURE)


static func _print_usage() -> void:
	print(
		(
			"Usage: godot --headless --path <project> "
			+ "--script res://addons/dialogue_framework/tools/compile_all_dlg.gd [-- --strict]\n"
			+ "  --strict  Require FlagManifest/CommandManifest paths and tiered validation (D15.3, D15.4)."
		)
	)
