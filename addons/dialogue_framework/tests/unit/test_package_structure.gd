extends GutTest


const PACKAGE_ROOT := "res://addons/dialogue_framework/"
const REQUIRED_DIRS: PackedStringArray = [
	"runtime/",
	"presentation/",
	"compiler/",
	"data/",
	"tests/",
]


func test_package_directories_exist() -> void:
	for dir_name: String in REQUIRED_DIRS:
		var path: String = PACKAGE_ROOT + dir_name
		assert_true(DirAccess.dir_exists_absolute(path), "Missing directory: %s" % path)
