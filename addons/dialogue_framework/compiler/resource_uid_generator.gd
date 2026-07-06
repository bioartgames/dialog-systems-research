class_name ResourceUidGenerator
extends RefCounted


static func resolve(source_path: String) -> String:
	return source_path.strip_edges()
