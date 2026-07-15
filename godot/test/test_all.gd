extends SceneTree

## Full headless suite: godot --headless --path . -s res://test/test_all.gd --quit-after 30


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: int = 0
	print("--- SuiteGrid ---")
	failed += load("res://test/suite_grid.gd").run() as int
	print("--- SuiteTiming ---")
	failed += load("res://test/suite_timing.gd").run() as int
	print("--- SuiteMatchInput ---")
	failed += load("res://test/suite_match_input.gd").run() as int
	print("--- SuiteJuice ---")
	failed += load("res://test/suite_juice.gd").run(self) as int
	print("--- SuiteSave ---")
	failed += load("res://test/suite_save.gd").run() as int
	print("--- SuiteAchievements ---")
	failed += load("res://test/suite_achievements.gd").run() as int

	if failed == 0:
		print("TEST_ALL_OK")
		quit(0)
	else:
		print("TEST_ALL_FAILED count=", failed)
		quit(1)
