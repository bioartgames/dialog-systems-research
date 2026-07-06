extends GutTest


const GoldenCompileSnapshot := preload(
	"res://addons/dialogue_framework/tests/helpers/golden_compile_snapshot.gd"
)

const FIXTURES: Array[String] = [
	"res://addons/dialogue_framework/tests/fixtures/minimal.dlg",
	"res://addons/dialogue_framework/tests/fixtures/branching.dlg",
]


func _compile_fixture(fixture_path: String) -> CompiledDialogue:
	var source_text: String = FileAccess.get_file_as_string(fixture_path)
	var result: Dictionary = DialogueCompiler.compile_string(source_text, fixture_path)
	assert_true(result["errors"].is_empty(), str(result["errors"]))
	return result["compiled"]


func test_fixture_compiles_without_errors() -> void:
	for fixture_path: String in FIXTURES:
		_compile_fixture(fixture_path)


func test_compile_output_matches_golden_snapshots() -> void:
	for fixture_path: String in FIXTURES:
		var compiled: CompiledDialogue = _compile_fixture(fixture_path)
		var actual: Dictionary = GoldenCompileSnapshot.serialize_compiled(compiled)
		var expected: Dictionary = GoldenCompileSnapshot.load_golden(fixture_path)
		var diff: String = GoldenCompileSnapshot.compare(actual, expected)
		assert_true(diff.is_empty(), diff)


func test_compiler_output_change_detected_against_golden() -> void:
	var fixture_path: String = FIXTURES[0]
	var compiled: CompiledDialogue = _compile_fixture(fixture_path)
	var actual: Dictionary = GoldenCompileSnapshot.serialize_compiled(compiled)
	var tampered: Dictionary = actual.duplicate(true)
	var line_ids: Array = tampered["lines"].keys()
	line_ids.sort()
	var first_line_id: String = String(line_ids[0])
	var line: Dictionary = tampered["lines"][first_line_id].duplicate(true)
	line["kind"] = LineKind.Kind.END
	tampered["lines"][first_line_id] = line
	var expected: Dictionary = GoldenCompileSnapshot.load_golden(fixture_path)
	var regression_diff: String = GoldenCompileSnapshot.compare(tampered, expected)
	assert_false(regression_diff.is_empty(), "Tampered output should differ from golden snapshot.")
