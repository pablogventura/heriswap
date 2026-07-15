class_name GameModeBase
extends RefCounted

const MODE_NORMAL := 0
const MODE_TILES_ATTACK := 1
const MODE_GO100 := 2

var points: int = 0
var time_sec: float = 0.0
var limit: float = 45.0
var bonus_type: int = 0
var level: int = 1
var finished: bool = false
var won: bool = false
var rng := RandomNumberGenerator.new()
var last_score_event: Dictionary = {}


func _init() -> void:
	rng.randomize()


func mode_id() -> int:
	return MODE_NORMAL


func enter(difficulty: int, start_level: int = 1) -> void:
	points = 0
	time_sec = 0.0
	finished = false
	won = false
	level = start_level
	bonus_type = rng.randi_range(0, Difficulty.to_grid_size(difficulty) - 1)


func update(dt: float, _grid: GridModel) -> void:
	time_sec += dt


func score_calc(nb: int, leaf_type: int, grid: GridModel) -> void:
	pass


func progress() -> float:
	return 0.0


func is_level_up() -> bool:
	return false


func on_level_up(grid: GridModel) -> void:
	pass


func hud_text() -> String:
	return str(points)


func to_dict() -> Dictionary:
	return {
		"mode": mode_id(),
		"points": points,
		"time_sec": time_sec,
		"limit": limit,
		"bonus_type": bonus_type,
		"level": level,
		"finished": finished,
		"won": won,
	}


func from_dict(data: Dictionary) -> void:
	points = int(data.get("points", 0))
	time_sec = float(data.get("time_sec", 0.0))
	limit = float(data.get("limit", limit))
	bonus_type = int(data.get("bonus_type", 0))
	level = int(data.get("level", 1))
	finished = bool(data.get("finished", false))
	won = bool(data.get("won", false))


static func create(mode: int) -> GameModeBase:
	match mode:
		MODE_TILES_ATTACK:
			return TilesAttackMode.new()
		MODE_GO100:
			return Go100SecondsMode.new()
		_:
			return NormalMode.new()
