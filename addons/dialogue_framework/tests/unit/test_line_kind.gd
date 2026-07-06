extends GutTest


const EXPECTED_KINDS: PackedStringArray = [
	"TITLE",
	"LINE",
	"CONDITION",
	"CHOICE",
	"COMMAND",
	"GOTO",
	"END",
]


func test_line_kind_enum_values_match_architecture() -> void:
	assert_eq(Array(LineKind.Kind.keys()), Array(EXPECTED_KINDS))
