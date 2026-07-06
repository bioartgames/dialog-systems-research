class_name DlgSingleFileScopeEnforcer
extends RefCounted


static func enforce(source_text: String, source_path: String = "") -> bool:
	var violations: PackedStringArray = DlgLexer.find_scope_violations(source_text, source_path)
	for violation: String in violations:
		push_error(violation)
	return violations.is_empty()


static func has_cross_file_import_syntax(source_text: String, source_path: String = "") -> bool:
	return not DlgLexer.find_scope_violations(source_text, source_path).is_empty()


static func get_violations(source_text: String, source_path: String = "") -> PackedStringArray:
	return DlgLexer.find_scope_violations(source_text, source_path)
