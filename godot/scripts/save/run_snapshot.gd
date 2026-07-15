extends Node

const SNAPSHOT_PATH := "user://run_snapshot.json"

var has_snapshot: bool = false


func clear() -> void:
	has_snapshot = false
	if FileAccess.file_exists(SNAPSHOT_PATH):
		DirAccess.remove_absolute(SNAPSHOT_PATH)


func save_run(data: Dictionary) -> void:
	data["version"] = 1
	data["saved_at"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(SNAPSHOT_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	has_snapshot = true


func load_run() -> Dictionary:
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		has_snapshot = false
		return {}
	var f := FileAccess.open(SNAPSHOT_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	has_snapshot = true
	return parsed


func has_saved_run() -> bool:
	return FileAccess.file_exists(SNAPSHOT_PATH)
