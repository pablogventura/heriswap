extends Node

const IDS := [
	"E6InARow", "EHardScore", "EFastAndFinish", "EResetGrid", "ETakeYourTime",
	"EExterminaScore", "ELevel1For2K", "ELevel10", "ERainbow", "EDoubleRainbow",
	"EBonusToExcess", "ELuckyLuke", "ETestEverything", "EBTAC", "EBTAM",
	"E666Loser", "ETheyGood", "EWhatToDo", "EBimBamBoum", "EDoubleInOne",
]

var unlocked: Dictionary = {}
var hard_mode: bool = false
var grid_resetted: bool = false
var game_duration: float = 0.0
var bonus_tiles_number: int = 0
var succ_every_type: Array = []
var rainbow_done: bool = false
var double_rainbow_done: bool = false


func _ready() -> void:
	_reset_session()
	var data := SaveService.load_achievements_state()
	for id in IDS:
		unlocked[id] = bool(data.get(id, false))


func _reset_session() -> void:
	succ_every_type = []
	succ_every_type.resize(8)
	for i in 8:
		succ_every_type[i] = 0
	bonus_tiles_number = 0
	grid_resetted = false
	game_duration = 0.0
	rainbow_done = false
	double_rainbow_done = false


func new_game(difficulty: int) -> void:
	hard_mode = difficulty == Difficulty.HARD
	_reset_session()


func _unlock(id: String) -> void:
	if unlocked.get(id, false):
		return
	unlocked[id] = true
	SaveService.save_achievements_state(unlocked)
	PlatformServices.unlock_achievement(id)


func s6_in_a_row(nb: int) -> void:
	if hard_mode and nb >= 6:
		_unlock("E6InARow")


func s_fast_and_finish(time_sec: float) -> void:
	if hard_mode and time_sec <= 53.0:
		_unlock("EFastAndFinish")


func s_reset_grid() -> void:
	if hard_mode and not grid_resetted:
		_unlock("EResetGrid")


func s_take_your_time() -> void:
	if hard_mode and game_duration > 900.0:
		_unlock("ETakeYourTime")


func s_extermina_score(points: int) -> void:
	if hard_mode and points > 100000:
		_unlock("EExterminaScore")


func s_level1_for_2k(level: int, points: int) -> void:
	if hard_mode and level == 1 and points >= 2000:
		_unlock("ELevel1For2K")


func s_level10(level: int) -> void:
	if hard_mode and level == 10:
		_unlock("ELevel10")


func s_rainbow(leaf_type: int) -> void:
	if not hard_mode:
		return
	if leaf_type >= 0 and leaf_type < succ_every_type.size():
		succ_every_type[leaf_type] = 1
	var all := true
	for v in succ_every_type:
		if int(v) == 0:
			all = false
			break
	if all:
		if not rainbow_done:
			_unlock("ERainbow")
			rainbow_done = true
			for i in succ_every_type.size():
				succ_every_type[i] = 0
		elif not double_rainbow_done:
			_unlock("EDoubleRainbow")
			double_rainbow_done = true


func s_bonus_to_excess(leaf_type: int, bonus: int, nb: int) -> void:
	if leaf_type == bonus:
		bonus_tiles_number += nb
	if hard_mode and bonus_tiles_number >= 100:
		_unlock("EBonusToExcess")


func s_hard_score_total(total_points: int) -> void:
	if total_points > 1000000:
		_unlock("EHardScore")


func mark_grid_reset() -> void:
	grid_resetted = true


func tick(dt: float) -> void:
	game_duration += dt


func is_unlocked(id: String) -> bool:
	return bool(unlocked.get(id, false))


func to_dict() -> Dictionary:
	return {
		"hard_mode": hard_mode,
		"grid_resetted": grid_resetted,
		"game_duration": game_duration,
		"bonus_tiles_number": bonus_tiles_number,
		"succ_every_type": succ_every_type.duplicate(),
		"rainbow_done": rainbow_done,
		"double_rainbow_done": double_rainbow_done,
	}


func from_dict(data: Dictionary) -> void:
	hard_mode = bool(data.get("hard_mode", false))
	grid_resetted = bool(data.get("grid_resetted", false))
	game_duration = float(data.get("game_duration", 0.0))
	bonus_tiles_number = int(data.get("bonus_tiles_number", 0))
	succ_every_type = data.get("succ_every_type", succ_every_type)
	rainbow_done = bool(data.get("rainbow_done", false))
	double_rainbow_done = bool(data.get("double_rainbow_done", false))
