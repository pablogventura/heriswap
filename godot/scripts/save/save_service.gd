extends Node

const SCORES_PATH := "user://scores.json"
const OPTIONS_PATH := "user://options.json"
const ACHIEVEMENTS_PATH := "user://achievements.json"
const SCHEMA_VERSION := 1

var options: Dictionary = {
	"version": SCHEMA_VERSION,
	"sound": true,
	"game_count": 0,
	"rate_never": false,
	"rate_later_count": 0,
	"locale": "en",
	"quest_index": 0,
	"daily_claimed": "",
	"reduce_motion": false,
	"seed": 0,
}


func _ready() -> void:
	load_options()


func load_options() -> void:
	var data := _read_json(OPTIONS_PATH)
	if data.is_empty():
		save_options()
		return
	options.merge(data, true)
	options["version"] = SCHEMA_VERSION


func save_options() -> void:
	options["version"] = SCHEMA_VERSION
	_write_json(OPTIONS_PATH, options)


func is_sound_on() -> bool:
	return bool(options.get("sound", true))


func set_sound(on: bool) -> void:
	options["sound"] = on
	save_options()
	AudioBus.apply_mute(not on)


func bump_game_count() -> void:
	options["game_count"] = int(options.get("game_count", 0)) + 1
	save_options()


func load_scores() -> Array:
	var data := _read_json(SCORES_PATH)
	if data.is_empty():
		return []
	return data.get("entries", [])


func add_score(entry: Dictionary) -> bool:
	## Returns true if entry entered top-5 for its mode+difficulty.
	var scores := load_scores()
	scores.append({
		"points": int(entry.get("points", 0)),
		"level": int(entry.get("level", 1)),
		"time": float(entry.get("time", 0.0)),
		"name": str(entry.get("name", "???")),
		"mode": int(entry.get("mode", 0)),
		"difficulty": int(entry.get("difficulty", 0)),
	})
	var filtered := _top5_for(scores, int(entry.mode), int(entry.difficulty))
	# Keep other modes intact.
	var kept: Array = []
	for s in scores:
		if int(s.mode) != int(entry.mode) or int(s.difficulty) != int(entry.difficulty):
			kept.append(s)
	kept.append_array(filtered)
	_write_json(SCORES_PATH, {"version": SCHEMA_VERSION, "entries": kept})
	for s in filtered:
		if s.name == entry.get("name") and int(s.points) == int(entry.get("points", 0)):
			return true
	return filtered.size() <= 5


func get_top5(mode: int, difficulty: int) -> Array:
	return _top5_for(load_scores(), mode, difficulty)


func _top5_for(all: Array, mode: int, difficulty: int) -> Array:
	var subset: Array = []
	for s in all:
		if int(s.mode) == mode and int(s.difficulty) == difficulty:
			subset.append(s)
	if mode == 1:
		# TilesAttack: lower time is better
		subset.sort_custom(func(a, b): return float(a.time) < float(b.time))
	else:
		subset.sort_custom(func(a, b): return int(a.points) > int(b.points))
	if subset.size() > 5:
		subset = subset.slice(0, 5)
	return subset


func is_high_score(mode: int, difficulty: int, points: int, time_sec: float) -> bool:
	var top := get_top5(mode, difficulty)
	if top.size() < 5:
		return true
	if mode == 1:
		return time_sec < float(top[top.size() - 1].time)
	return points > int(top[top.size() - 1].points)


func load_achievements_state() -> Dictionary:
	return _read_json(ACHIEVEMENTS_PATH)


func save_achievements_state(state: Dictionary) -> void:
	state["version"] = SCHEMA_VERSION
	_write_json(ACHIEVEMENTS_PATH, state)


const PROGRESS_PATH := "user://scrap_progress.json"
const SLOT_PATH := "user://save_slot_%d.json"


func save_scrap_progress(boosters: Dictionary, codex: Dictionary) -> void:
	_write_json(PROGRESS_PATH, {
		"version": SCHEMA_VERSION,
		"boosters": boosters,
		"codex": codex,
	})


func load_scrap_progress() -> Dictionary:
	return _read_json(PROGRESS_PATH)


func export_save_blob() -> String:
	return JSON.stringify({
		"options": options,
		"scores": load_scores(),
		"achievements": load_achievements_state(),
		"progress": load_scrap_progress(),
	}, "\t")


func import_save_blob(text: String) -> bool:
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	if parsed.has("options") and typeof(parsed.options) == TYPE_DICTIONARY:
		options.merge(parsed.options, true)
		save_options()
	if parsed.has("scores"):
		_write_json(SCORES_PATH, {"version": SCHEMA_VERSION, "entries": parsed.scores})
	if parsed.has("achievements") and typeof(parsed.achievements) == TYPE_DICTIONARY:
		save_achievements_state(parsed.achievements)
	if parsed.has("progress") and typeof(parsed.progress) == TYPE_DICTIONARY:
		_write_json(PROGRESS_PATH, parsed.progress)
	return true


func write_slot(slot: int, blob: Dictionary) -> void:
	_write_json(SLOT_PATH % clampi(slot, 0, 2), blob)


func read_slot(slot: int) -> Dictionary:
	return _read_json(SLOT_PATH % clampi(slot, 0, 2))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveService: cannot write %s" % path)
		return
	f.store_string(JSON.stringify(data, "\t"))
