class_name NormalMode
extends GameModeBase

## Score race: timer + remain[] objectives per leaf type + branch removal.

var remain: Array = []
var help_available: bool = true
var branch_view: BranchLeavesView


func mode_id() -> int:
	return MODE_NORMAL


func enter(difficulty: int, start_level: int = 1) -> void:
	super.enter(difficulty, start_level)
	_start_level(start_level, Difficulty.to_grid_size(difficulty))


func bind_branch(view: BranchLeavesView) -> void:
	branch_view = view
	if branch_view:
		branch_view.generate(remain.size(), 6)


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
	if branch_view:
		branch_view.generate(type_count, 6)


func update(dt: float, _grid: GridModel) -> void:
	super.update(dt, _grid)
	if time_sec >= limit:
		finished = true
		won = false


static func level_to_leave_to_delete(nb: int, initial_leave_count: int, removed_leave: int, left_on_branch: int) -> int:
	var left_for_type := maxi(0, initial_leave_count - (removed_leave + nb))
	if left_for_type <= 3:
		return maxi(0, left_on_branch - left_for_type)
	var denom := float(maxi(1, initial_leave_count - 3))
	var should_be_removed := int(floor(3.0 * float(removed_leave + nb) / denom))
	should_be_removed = clampi(should_be_removed, 0, 3)
	var already := 6 - left_on_branch
	return should_be_removed - already


func score_calc(nb: int, leaf_type: int, grid: GridModel) -> void:
	if leaf_type == bonus_type:
		points += int(10 * level * 2 * nb * nb * nb / 6)
	else:
		points += int(10 * level * nb * nb * nb / 6)
	var initial := 2 + level
	var removed_before := 0
	if leaf_type >= 0 and leaf_type < remain.size():
		removed_before = initial - int(remain[leaf_type])
	var left_branch := 6
	if branch_view:
		left_branch = branch_view.count_of_type(leaf_type)
	var to_delete := level_to_leave_to_delete(nb, initial, removed_before, left_branch)
	if branch_view and to_delete > 0:
		branch_view.remove_of_type(leaf_type, to_delete)
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
