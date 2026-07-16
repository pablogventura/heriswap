class_name TilesAttackMode
extends GameModeBase

var leaves_done: int = 0
var branch_view: BranchLeavesView


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
	bonus_type = rng.randi_range(0, Difficulty.to_type_count(difficulty) - 1)


func bind_branch(view: BranchLeavesView) -> void:
	branch_view = view
	if branch_view:
		branch_view.generate(8, 6)


static func level_to_leave_to_delete(leaves_max_size: int, limit_v: int, nb: int, leaves_done_v: int) -> int:
	var total_branch := leaves_max_size
	var break_comb := limit_v - 20
	var to_delete := 0
	if leaves_done_v >= break_comb or limit_v <= 30:
		to_delete = (leaves_done_v + nb) * total_branch / limit_v - leaves_done_v * total_branch / limit_v
	elif leaves_done_v < break_comb and leaves_done_v + nb <= break_comb:
		var break_branch := total_branch - 20
		to_delete = (leaves_done_v + nb) * break_branch / break_comb - leaves_done_v * break_branch / break_comb
	else:
		var break_branch := total_branch - 20
		to_delete = break_branch - (break_branch * leaves_done_v) / break_comb
		to_delete += leaves_done_v + nb - break_comb
	return maxi(0, to_delete)


func update(dt: float, grid: GridModel) -> void:
	super.update(dt, grid)
	if leaves_done >= int(limit):
		finished = true
		won = true


func score_calc(nb: int, leaf_type: int, _grid: GridModel) -> void:
	var add := nb
	if leaf_type == bonus_type:
		add = 2 * nb
		points += int(10 * nb * nb * nb / 3) # cube-ish bonus path
	else:
		points += int(10 * nb * nb * nb / 6)
	var to_del := level_to_leave_to_delete(48, int(limit), add, leaves_done)
	if branch_view and to_del > 0:
		branch_view.remove_any(to_del)
	leaves_done += add
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
