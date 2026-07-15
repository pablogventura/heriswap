class_name GridModel
extends RefCounted

## Pure grid data + match-3 rules ported from HeriswapGridSystem.

const NB_MIN := 3

var grid_size: int = 8
var type_count: int = 8
## cells[x][y] = leaf type or -1 if empty. y=0 is bottom.
var cells: Array = []

signal cells_changed


func set_difficulty(diff: int) -> void:
	grid_size = Difficulty.to_grid_size(diff)
	type_count = grid_size
	clear()


func clear() -> void:
	cells.clear()
	for x in grid_size:
		var col: Array = []
		col.resize(grid_size)
		for y in grid_size:
			col[y] = -1
		cells.append(col)
	cells_changed.emit()


func is_valid(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_size and y < grid_size


func get_cell(x: int, y: int) -> int:
	if not is_valid(x, y):
		return -1
	return cells[x][y]


func set_cell(x: int, y: int, leaf_type: int) -> void:
	if is_valid(x, y):
		cells[x][y] = leaf_type


func fill_random(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	clear()
	for x in grid_size:
		for y in grid_size:
			cells[x][y] = rng.randi_range(0, type_count - 1)
	# Avoid starting with combinations when possible.
	var guard := 0
	while not look_for_combinations().is_empty() and guard < 50:
		for combo in look_for_combinations():
			for p in combo.points:
				cells[int(p.x)][int(p.y)] = rng.randi_range(0, type_count - 1)
		guard += 1
	cells_changed.emit()


func fill_until_playable(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var attempts := 0
	while attempts < 80:
		fill_random(rng)
		if still_combinations() and look_for_combinations().is_empty():
			return
		attempts += 1
	# Fallback: accept any filled grid with moves or combos.
	fill_random(rng)
	cells_changed.emit()


## Returns Array of { "type": int, "points": Array[Vector2i] }
func look_for_combinations() -> Array:
	var combos: Array = []
	var checked_v := {}
	var checked_h := {}

	for x in grid_size:
		for y in grid_size:
			var t: int = cells[x][y]
			if t < 0:
				continue
			var key := Vector2i(x, y)
			if not checked_v.has(key):
				var points_v: Array[Vector2i] = []
				var k := y
				while k >= 0 and cells[x][k] == t:
					points_v.append(Vector2i(x, k))
					checked_v[Vector2i(x, k)] = true
					k -= 1
				k = y + 1
				while k < grid_size and cells[x][k] == t:
					points_v.append(Vector2i(x, k))
					checked_v[Vector2i(x, k)] = true
					k += 1
				if points_v.size() >= NB_MIN:
					combos.append({"type": t, "points": points_v})

			if not checked_h.has(key):
				var points_h: Array[Vector2i] = []
				var kx := x
				while kx >= 0 and cells[kx][y] == t:
					points_h.append(Vector2i(kx, y))
					checked_h[Vector2i(kx, y)] = true
					kx -= 1
				kx = x + 1
				while kx < grid_size and cells[kx][y] == t:
					points_h.append(Vector2i(kx, y))
					checked_h[Vector2i(kx, y)] = true
					kx += 1
				if points_h.size() >= NB_MIN:
					combos.append({"type": t, "points": points_h})

	return _merge_combinations(combos)


func _merge_combinations(combos: Array) -> Array:
	var merged: Array = []
	var used := {}
	for i in combos.size():
		if used.has(i):
			continue
		var cur: Dictionary = combos[i].duplicate(true)
		var changed := true
		while changed:
			changed = false
			for j in combos.size():
				if j == i or used.has(j):
					continue
				var other: Dictionary = combos[j]
				if other.type != cur.type:
					continue
				if _points_intersect(cur.points, other.points):
					for p in other.points:
						if not _in_points(cur.points, p):
							cur.points.append(p)
					used[j] = true
					changed = true
		merged.append(cur)
	return merged


func _points_intersect(a: Array, b: Array) -> bool:
	for p in a:
		if _in_points(b, p):
			return true
	return false


func _in_points(arr: Array, p: Vector2i) -> bool:
	for q in arr:
		if q == p:
			return true
	return false


## Returns Array of { "x": int, "from_y": int, "to_y": int }
func tile_fall() -> Array:
	var result: Array = []
	for x in grid_size:
		for y in grid_size:
			if cells[x][y] >= 0:
				continue
			var k := y + 1
			while k < grid_size:
				if cells[x][k] >= 0:
					var fall_height := k - y
					while k < grid_size:
						if cells[x][k] >= 0:
							result.append({"x": x, "from_y": k, "to_y": k - fall_height})
						else:
							fall_height += 1
						k += 1
					break
				k += 1
			break
	return result


func apply_falls(falls: Array) -> void:
	# Apply from low to_y upward per column to avoid overwrite issues.
	var by_col := {}
	for f in falls:
		var x: int = f.x
		if not by_col.has(x):
			by_col[x] = []
		by_col[x].append(f)
	for x in by_col.keys():
		var list: Array = by_col[x]
		list.sort_custom(func(a, b): return a.to_y < b.to_y)
		# Collect types then clear sources then write.
		var moves: Array = []
		for f in list:
			moves.append({"to": f.to_y, "type": cells[x][f.from_y]})
		for f in list:
			cells[x][f.from_y] = -1
		for m in moves:
			cells[x][m.to] = m.type
	cells_changed.emit()


func remove_points(points: Array) -> void:
	for p in points:
		cells[int(p.x)][int(p.y)] = -1
	cells_changed.emit()


func swap_cells(a: Vector2i, b: Vector2i) -> void:
	var tmp: int = cells[a.x][a.y]
	cells[a.x][a.y] = cells[b.x][b.y]
	cells[b.x][b.y] = tmp
	cells_changed.emit()


func would_swap_match(a: Vector2i, b: Vector2i) -> bool:
	if not is_valid(a.x, a.y) or not is_valid(b.x, b.y):
		return false
	if abs(a.x - b.x) + abs(a.y - b.y) != 1:
		return false
	swap_cells(a, b)
	var ok := not look_for_combinations().is_empty()
	swap_cells(a, b)
	return ok


func new_combi_on_switch(x: int, y: int) -> bool:
	# Test right and top neighbors (ported from NewCombiOnSwitch).
	if is_valid(x + 1, y) and cells[x + 1][y] >= 0 and cells[x][y] >= 0:
		swap_cells(Vector2i(x, y), Vector2i(x + 1, y))
		var ok_r := not look_for_combinations().is_empty()
		swap_cells(Vector2i(x, y), Vector2i(x + 1, y))
		if ok_r:
			return true
	if is_valid(x, y + 1) and cells[x][y + 1] >= 0 and cells[x][y] >= 0:
		swap_cells(Vector2i(x, y), Vector2i(x, y + 1))
		var ok_t := not look_for_combinations().is_empty()
		swap_cells(Vector2i(x, y), Vector2i(x, y + 1))
		if ok_t:
			return true
	return false


func still_combinations() -> bool:
	if not look_for_combinations().is_empty():
		return true
	for x in grid_size:
		for y in grid_size:
			if cells[x][y] < 0:
				continue
			if new_combi_on_switch(x, y):
				return true
	return false


func fill_blanks(rng: RandomNumberGenerator = null) -> Array:
	## Returns spawned cells as Array of Vector2i.
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var spawned: Array = []
	for x in grid_size:
		for y in grid_size:
			if cells[x][y] < 0:
				cells[x][y] = rng.randi_range(0, type_count - 1)
				spawned.append(Vector2i(x, y))
	cells_changed.emit()
	return spawned


func find_hint() -> Array:
	## Returns two Vector2i to swap, or empty.
	for x in grid_size:
		for y in grid_size:
			if cells[x][y] < 0:
				continue
			for n in [Vector2i(x + 1, y), Vector2i(x, y + 1)]:
				if not is_valid(n.x, n.y):
					continue
				if would_swap_match(Vector2i(x, y), n):
					return [Vector2i(x, y), n]
	return []


func to_dict() -> Dictionary:
	var flat: Array = []
	for x in grid_size:
		for y in grid_size:
			flat.append(cells[x][y])
	return {"grid_size": grid_size, "type_count": type_count, "cells": flat}


func from_dict(data: Dictionary) -> void:
	grid_size = int(data.get("grid_size", 8))
	type_count = int(data.get("type_count", grid_size))
	clear()
	var flat: Array = data.get("cells", [])
	var idx := 0
	for x in grid_size:
		for y in grid_size:
			if idx < flat.size():
				cells[x][y] = int(flat[idx])
			idx += 1
	cells_changed.emit()
