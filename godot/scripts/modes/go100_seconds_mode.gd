class_name Go100SecondsMode
extends GameModeBase

var squall_triggered: bool = false
var squall_active: bool = false
var squall_duration: float = 0.0
var branch_view: BranchLeavesView
signal squall_started(bonus: int)
signal squall_ended


func mode_id() -> int:
	return MODE_GO100


func enter(difficulty: int, start_level: int = 1) -> void:
	super.enter(difficulty, start_level)
	limit = 100.0
	time_sec = 0.0
	points = 0
	squall_triggered = false
	squall_active = false
	squall_duration = 0.0
	bonus_type = rng.randi_range(0, Difficulty.to_type_count(difficulty) - 1)


func bind_branch(view: BranchLeavesView) -> void:
	branch_view = view
	if branch_view:
		branch_view.generate(10, 8)
		branch_view.set_all_types(bonus_type)


func update(dt: float, _grid: GridModel) -> void:
	super.update(dt, _grid)
	if time_sec >= limit:
		finished = true
		won = true
		return
	if squall_active:
		squall_duration += dt
		if branch_view:
			branch_view.grow_all(squall_duration)
		if squall_duration >= 1.6:
			squall_active = false
			squall_duration = 0.0
			squall_ended.emit()
	elif branch_view and branch_view.visible_count() == 0:
		var types := 8
		if _grid:
			types = _grid.type_count
		bonus_type = rng.randi_range(0, maxi(0, types - 1))
		branch_view.generate(10, 8)
		branch_view.set_all_types(bonus_type)
		branch_view.grow_all(0.01)
		squall_active = true
		squall_triggered = true
		squall_duration = 0.0
		squall_started.emit(bonus_type)


func score_calc(nb: int, leaf_type: int, grid: GridModel) -> void:
	var score := 10.0 * float(nb * nb * nb * nb)
	match Difficulty.from_grid_size(grid.grid_size):
		Difficulty.MEDIUM:
			score *= 2.0
		Difficulty.HARD:
			score *= 4.0
	if leaf_type == bonus_type:
		score *= 2.0
		if branch_view:
			branch_view.remove_any(2 * nb)
	else:
		if branch_view:
			branch_view.remove_any(nb)
	points += int(score)
	last_score_event = {"nb": nb, "type": leaf_type, "bonus": bonus_type, "points": points, "level": level}


func progress() -> float:
	return minf(1.0, time_sec / limit)


func hud_text() -> String:
	return "%d  %.0fs" % [points, maxf(0.0, limit - time_sec)]


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["squall_triggered"] = squall_triggered
	d["squall_active"] = squall_active
	d["squall_duration"] = squall_duration
	return d


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	squall_triggered = bool(data.get("squall_triggered", false))
	squall_active = bool(data.get("squall_active", false))
	squall_duration = float(data.get("squall_duration", 0.0))
