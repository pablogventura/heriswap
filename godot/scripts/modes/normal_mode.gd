class_name NormalMode
extends GameModeBase

## Score race: timer + remain[] objectives per leaf type.

var remain: Array = []
var help_available: bool = true


func mode_id() -> int:
	return MODE_NORMAL


func enter(difficulty: int, start_level: int = 1) -> void:
	super.enter(difficulty, start_level)
	_start_level(start_level, Difficulty.to_grid_size(difficulty))


func _start_level(lvl: int, type_count: int) -> void:
	level = lvl
	limit = maxf(45.0 - float(level - 1), 10.0)
	time_sec = 0.0
	remain.clear()
	remain.resize(type_count)
	for i in type_count:
		remain[i] = 2 + level
	help_available = level < 10
	bonus_type = rng.randi_range(0, type_count - 1)


func update(dt: float, _grid: GridModel) -> void:
	super.update(dt, _grid)
	if time_sec >= limit:
		finished = true
		won = false


func score_calc(nb: int, leaf_type: int, grid: GridModel) -> void:
	if leaf_type == bonus_type:
		points += int(10 * level * 2 * nb * nb * nb / 6)
	else:
		points += int(10 * level * nb * nb * nb / 6)
	if leaf_type >= 0 and leaf_type < remain.size():
		remain[leaf_type] = maxi(0, int(remain[leaf_type]) - nb)
	time_sec = maxf(0.0, time_sec - minf(time_sec, 2.0 * float(nb) / float(grid.grid_size)))
	last_score_event = {"nb": nb, "type": leaf_type, "bonus": bonus_type, "points": points, "level": level}


func progress() -> float:
	return minf(1.0, time_sec / limit)


func is_level_up() -> bool:
	for r in remain:
		if int(r) != 0:
			return false
	return true


func on_level_up(grid: GridModel) -> void:
	time_sec = maxf(0.0, time_sec - minf(20.0 * 8.0 / float(grid.grid_size), time_sec))
	_start_level(level + 1, grid.type_count)


func stress_amount() -> float:
	if time_sec > limit - 10.0:
		return (time_sec - (limit - 10.0)) / 10.0
	return 0.0


func hud_text() -> String:
	return "Lv%d  %d" % [level, points]


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["remain"] = remain.duplicate()
	d["help_available"] = help_available
	return d


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	remain = data.get("remain", remain)
	help_available = bool(data.get("help_available", true))
