class_name DialogueSnapshot
extends RefCounted


const KEY_RESOURCE_UID := &"resource_uid"
const KEY_ENTRY_LABEL := &"entry_label"
const KEY_LINE_ID := &"line_id"

var resource_uid: String = ""
var entry_label: String = ""
var line_id: String = ""


func to_dict() -> Dictionary:
	return {
		KEY_RESOURCE_UID: resource_uid,
		KEY_ENTRY_LABEL: entry_label,
		KEY_LINE_ID: line_id,
	}


static func from_dict(data: Dictionary) -> DialogueSnapshot:
	var snapshot := DialogueSnapshot.new()
	snapshot.resource_uid = String(data.get(KEY_RESOURCE_UID, ""))
	snapshot.entry_label = String(data.get(KEY_ENTRY_LABEL, ""))
	snapshot.line_id = String(data.get(KEY_LINE_ID, ""))
	return snapshot
