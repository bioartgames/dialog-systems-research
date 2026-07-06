extends GutTest


const EXPECTED_PHASES: PackedStringArray = [
	"Idle",
	"PresentingLine",
	"AwaitingInput",
	"AwaitingChoice",
	"ExecutingCommand",
	"Ended",
]


func test_conversation_phase_enum_values_match_architecture() -> void:
	assert_eq(Array(ConversationPhase.Phase.keys()), Array(EXPECTED_PHASES))
