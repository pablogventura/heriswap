class_name QuestMode
extends GameModeBase

## Move-limited Quest with stickers, score, ingredients, and order objectives.

var moves_left: int = 20
var moves_max: int = 20
var objective: String = "clear_stickers" ## clear_stickers | reach_score | ingredients | orders | zen
var target_score: int = 5000
var level_id: String = "q001"
var sticky_start: int = 0
var zen: bool = false
var near_miss_hint_used: bool = false
var sugar_crush_done: bool = false

## ingredients: clear N of target_color (tracked via score_calc types)
var ingredient_target: int = 8
var ingredient_color: int = 0
var ingredient_done: int = 0

## orders: [{ "color": 0, "count": 5 }, ...]
var orders: Array = []
var order_progress: Dictionary = {} ## color -> cleared count


func mode_id() -> int:
	return GameModeBase.MODE_ZEN if zen else GameModeBase.MODE_QUEST


func enter(difficulty: int, start_level: int = 1) -> void:
	super.enter(difficulty, start_level)
	zen = false
	limit = 99999.0
	moves_left = moves_max
	ingredient_done = 0
	order_progress.clear()
	near_miss_hint_used = false
	sugar_crush_done = false


func apply_level_def(def: Dictionary) -> void:
	level_id = str(def.get("id", level_id))
	objective = str(def.get("objective", "clear_stickers"))
	moves_max = int(def.get("moves", 20))
	moves_left = moves_max
	target_score = int(def.get("target_score", 5000))
	zen = bool(def.get("zen", false))
	ingredient_target = int(def.get("ingredient_target", 8))
	ingredient_color = int(def.get("ingredient_color", 0))
	ingredient_done = 0
	orders = def.get("orders", [])
	if typeof(orders) != TYPE_ARRAY:
		orders = []
	order_progress.clear()
	for o in orders:
		order_progress[int(o.get("color", 0))] = 0
	if zen:
		objective = "zen"
		moves_left = 999
		moves_max = 999


func spend_move() -> void:
	if zen or finished:
		return
	moves_left = maxi(0, moves_left - 1)


func score_calc(nb: int, leaf_type: int, _grid: GridModel) -> void:
	var gained := nb * nb * 40
	if leaf_type == bonus_type:
		gained *= 2
	points += gained
	last_score_event = {"nb": nb, "type": leaf_type, "points": gained, "level": level}
	if objective == "ingredients" and leaf_type == ingredient_color:
		ingredient_done += nb
	if objective == "orders" and order_progress.has(leaf_type):
		order_progress[leaf_type] = int(order_progress[leaf_type]) + nb


func on_board_settled(grid: GridModel) -> void:
	if finished or zen:
		return
	match objective:
		"clear_stickers":
			if grid.count_stickers() <= 0:
				finished = true
				won = true
			elif moves_left <= 0:
				finished = true
				won = false
		"reach_score":
			if points >= target_score:
				finished = true
				won = true
			elif moves_left <= 0:
				finished = true
				won = false
		"ingredients":
			if ingredient_done >= ingredient_target:
				finished = true
				won = true
			elif moves_left <= 0:
				finished = true
				won = false
		"orders":
			if _orders_complete():
				finished = true
				won = true
			elif moves_left <= 0:
				finished = true
				won = false
		_:
			if moves_left <= 0:
				finished = true
				won = points >= target_score


func _orders_complete() -> bool:
	for o in orders:
		var c := int(o.get("color", 0))
		var need := int(o.get("count", 1))
		if int(order_progress.get(c, 0)) < need:
			return false
	return orders.size() > 0


func wants_sugar_crush(grid: GridModel) -> bool:
	return finished and won and not zen and moves_left > 0 and not sugar_crush_done and _has_special(grid)


func _has_special(grid: GridModel) -> bool:
	for x in grid.grid_size:
		for y in grid.grid_size:
			if grid.get_special(x, y) != MatchPiece.Special.NONE:
				return true
	return false


func is_near_miss(grid: GridModel) -> bool:
	return objective == "clear_stickers" and grid.count_stickers() == 1 and not near_miss_hint_used


func progress() -> float:
	match objective:
		"reach_score":
			return clampf(float(points) / float(maxi(1, target_score)), 0.0, 1.0)
		"ingredients":
			return clampf(float(ingredient_done) / float(maxi(1, ingredient_target)), 0.0, 1.0)
		"orders":
			var need := 0
			var have := 0
			for o in orders:
				var c := int(o.get("color", 0))
				var n := int(o.get("count", 1))
				need += n
				have += mini(n, int(order_progress.get(c, 0)))
			return clampf(float(have) / float(maxi(1, need)), 0.0, 1.0)
		"clear_stickers":
			if sticky_start <= 0:
				return 1.0 if _last_sticker_count <= 0 else 0.0
			return 1.0 - clampf(float(_last_sticker_count) / float(sticky_start), 0.0, 1.0)
		_:
			return 0.0


var _last_sticker_count: int = 0


func sync_stickers(grid: GridModel) -> void:
	_last_sticker_count = grid.count_stickers()


func hud_text() -> String:
	if zen:
		return "%s  %d" % [tr("score"), points]
	match objective:
		"reach_score":
			return "%s %d/%d  ·  %s %d" % [tr("score"), points, target_score, tr("moves"), moves_left]
		"ingredients":
			return "%s %d/%d  ·  %s %d" % [tr("ingredients"), ingredient_done, ingredient_target, tr("moves"), moves_left]
		"orders":
			return "%s %d%%  ·  %s %d" % [tr("orders"), int(progress() * 100.0), tr("moves"), moves_left]
		_:
			return "%s %d  ·  %s %d" % [tr("stickers"), _last_sticker_count, tr("moves"), moves_left]


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["moves_left"] = moves_left
	d["moves_max"] = moves_max
	d["objective"] = objective
	d["target_score"] = target_score
	d["level_id"] = level_id
	d["zen"] = zen
	d["sticky_start"] = sticky_start
	d["ingredient_done"] = ingredient_done
	d["ingredient_target"] = ingredient_target
	d["ingredient_color"] = ingredient_color
	d["orders"] = orders
	d["order_progress"] = order_progress
	d["near_miss_hint_used"] = near_miss_hint_used
	d["sugar_crush_done"] = sugar_crush_done
	return d


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	moves_left = int(data.get("moves_left", moves_max))
	moves_max = int(data.get("moves_max", 20))
	objective = str(data.get("objective", objective))
	target_score = int(data.get("target_score", target_score))
	level_id = str(data.get("level_id", level_id))
	zen = bool(data.get("zen", false))
	sticky_start = int(data.get("sticky_start", 0))
	ingredient_done = int(data.get("ingredient_done", 0))
	ingredient_target = int(data.get("ingredient_target", 8))
	ingredient_color = int(data.get("ingredient_color", 0))
	orders = data.get("orders", [])
	order_progress = data.get("order_progress", {})
	near_miss_hint_used = bool(data.get("near_miss_hint_used", false))
	sugar_crush_done = bool(data.get("sugar_crush_done", false))
