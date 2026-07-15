class_name Go100SecondsMode
extends GameModeBase

var squall_triggered: bool = false


func mode_id() -> int:
	return MODE_GO100


func enter(difficulty: int, start_level: int = 1) -> void:
	super.enter(difficulty, start_level)
	limit = 100.0
	time_sec = 0.0
	points = 0
	squall_triggered = false
	bonus_type = rng.randi_range(0, Difficulty.to_grid_size(difficulty) - 1)


func update(dt: float, _grid: GridModel) -> void:
	super.update(dt, _grid)
	if time_sec >= limit:
		finished = true
		won = true


func score_calc(nb: int, leaf_type: int, grid: GridModel) -> void:
	var score := 10.0 * float(nb * nb * nb * nb)
	match Difficulty.from_grid_size(grid.grid_size):
		Difficulty.MEDIUM:
			score *= 2.0
		Difficulty.HARD:
			score *= 4.0
	if leaf_type == bonus_type:
		score *= 2.0
	points += int(score)
	last_score_event = {"nb": nb, "type": leaf_type, "bonus": bonus_type, "points": points, "level": level}


func progress() -> float:
	return minf(1.0, time_sec / limit)


func hud_text() -> String:
	return "%d  %.0fs" % [points, maxf(0.0, limit - time_sec)]


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["squall_triggered"] = squall_triggered
	return d


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	squall_triggered = bool(data.get("squall_triggered", false))
