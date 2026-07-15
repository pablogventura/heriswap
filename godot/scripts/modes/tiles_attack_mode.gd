class_name TilesAttackMode
extends GameModeBase

var leaves_done: int = 0


func mode_id() -> int:
	return MODE_TILES_ATTACK


func enter(difficulty: int, start_level: int = 1) -> void:
	super.enter(difficulty, start_level)
	leaves_done = 0
	time_sec = 0.0
	match difficulty:
		Difficulty.EASY:
			limit = 30.0
		_:
			limit = 100.0
	bonus_type = rng.randi_range(0, Difficulty.to_grid_size(difficulty) - 1)


func update(dt: float, grid: GridModel) -> void:
	super.update(dt, grid)
	if leaves_done >= int(limit):
		finished = true
		won = true
		points = maxi(points, int(100000.0 / maxf(time_sec, 1.0)))


func score_calc(nb: int, leaf_type: int, _grid: GridModel) -> void:
	var add := nb
	if leaf_type == bonus_type:
		add = 2 * nb
	leaves_done += add
	points += add
	last_score_event = {"nb": nb, "type": leaf_type, "bonus": bonus_type, "points": points, "level": level}


func progress() -> float:
	return minf(1.0, float(leaves_done) / limit)


func hud_text() -> String:
	return "%d / %d" % [leaves_done, int(limit)]


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["leaves_done"] = leaves_done
	return d


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	leaves_done = int(data.get("leaves_done", 0))
