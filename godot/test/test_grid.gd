extends SceneTree

## Headless grid unit tests (compat entry): godot --headless -s res://test/test_grid.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: int = load("res://test/suite_grid.gd").run()
	failed += load("res://test/suite_timing.gd").run()
	failed += load("res://test/suite_specials_quest.gd").run()
	if failed == 0:
		print("TEST_GRID_OK")
		quit(0)
	else:
		print("TEST_GRID_FAILED count=", failed)
		quit(1)
