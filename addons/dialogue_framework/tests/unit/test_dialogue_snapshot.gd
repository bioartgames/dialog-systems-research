extends GutTest


func test_snapshot_round_trip() -> void:
	var snapshot := DialogueSnapshot.new()
	snapshot.resource_uid = "uid_roll"
	snapshot.entry_label = "start"
	snapshot.line_id = "res://npcs/roll.dlg::4"

	var restored := DialogueSnapshot.from_dict(snapshot.to_dict())
	assert_eq(restored.resource_uid, snapshot.resource_uid)
	assert_eq(restored.entry_label, snapshot.entry_label)
	assert_eq(restored.line_id, snapshot.line_id)


func test_snapshot_dict_contains_required_fields() -> void:
	var data: Dictionary = DialogueSnapshot.new().to_dict()
	assert_true(data.has(DialogueSnapshot.KEY_RESOURCE_UID))
	assert_true(data.has(DialogueSnapshot.KEY_ENTRY_LABEL))
	assert_true(data.has(DialogueSnapshot.KEY_LINE_ID))
