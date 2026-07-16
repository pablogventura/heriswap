extends SceneTree

## CLI: godot --headless -s res://test/validate_levels.gd --quit-after 15


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var n: int = LevelValidator.run_cli()
	quit(0 if n == 0 else 1)
