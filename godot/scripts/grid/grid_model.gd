class_name GridModel
extends RefCounted

## ScrapSwap grid: colors + specials + blockers + stickers + playable mask.

const NB_MIN := 3

var grid_size: int = 8
var type_count: int = 8
## cells[x][y] = color int or -1. y=0 is bottom.
var cells: Array = []
var specials: Array = []
var blockers: Array = []
var blocker_layers: Array = []
var stickers: Array = []
var playable: Array = []

signal cells_changed


func set_difficulty(diff: int) -> void:
	grid_size = Difficulty.to_grid_size(diff)
	type_count = grid_size
	clear()


func set_size(size: int, types: int = -1) -> void:
	grid_size = clampi(size, 5, 9)
	type_count = types if types > 0 else grid_size
	clear()


func clear() -> void:
	cells.clear()
	specials.clear()
	blockers.clear()
	blocker_layers.clear()
	stickers.clear()
	playable.clear()
	for x in grid_size:
		var col_c: Array = []
		var col_s: Array = []
		var col_b: Array = []
		var col_bl: Array = []
		var col_st: Array = []
		var col_p: Array = []
		col_c.resize(grid_size)
		col_s.resize(grid_size)
		col_b.resize(grid_size)
		col_bl.resize(grid_size)
		col_st.resize(grid_size)
		col_p.resize(grid_size)
		for y in grid_size:
			col_c[y] = -1
			col_s[y] = MatchPiece.Special.NONE
			col_b[y] = MatchPiece.Blocker.NONE
			col_bl[y] = 0
			col_st[y] = 0
			col_p[y] = true
		cells.append(col_c)
		specials.append(col_s)
		blockers.append(col_b)
		blocker_layers.append(col_bl)
		stickers.append(col_st)
		playable.append(col_p)
	cells_changed.emit()


func is_valid(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_size and y < grid_size


func is_playable(x: int, y: int) -> bool:
	return is_valid(x, y) and bool(playable[x][y])


func get_cell(x: int, y: int) -> int:
	if not is_valid(x, y):
		return -1
	if not playable[x][y]:
		return -1
	return cells[x][y]


func get_special(x: int, y: int) -> int:
	if not is_playable(x, y):
		return MatchPiece.Special.NONE
	return int(specials[x][y])


func get_sticker(x: int, y: int) -> int:
	if not is_playable(x, y):
		return 0
	return int(stickers[x][y])


func get_blocker(x: int, y: int) -> int:
	if not is_playable(x, y):
		return MatchPiece.Blocker.NONE
	return int(blockers[x][y])


func set_cell(x: int, y: int, leaf_type: int) -> void:
	if is_valid(x, y) and playable[x][y]:
		cells[x][y] = leaf_type
		if leaf_type < 0:
			specials[x][y] = MatchPiece.Special.NONE


func set_special(x: int, y: int, special: int) -> void:
	if is_playable(x, y):
		specials[x][y] = special


func set_sticker(x: int, y: int, layers: int) -> void:
	if is_playable(x, y):
		stickers[x][y] = maxi(0, layers)


func set_blocker(x: int, y: int, kind: int, layers: int = 1) -> void:
	if is_playable(x, y):
		blockers[x][y] = kind
		blocker_layers[x][y] = layers if kind != MatchPiece.Blocker.NONE else 0


func set_playable_mask(mask: Array) -> void:
	## mask[x][y] bool, same size.
	for x in mini(grid_size, mask.size()):
		var col: Array = mask[x]
		for y in mini(grid_size, col.size()):
			playable[x][y] = bool(col[y])
			if not playable[x][y]:
				cells[x][y] = -1
				specials[x][y] = MatchPiece.Special.NONE


func fill_random(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	for x in grid_size:
		for y in grid_size:
			if not playable[x][y]:
				cells[x][y] = -1
				continue
			cells[x][y] = rng.randi_range(0, type_count - 1)
			specials[x][y] = MatchPiece.Special.NONE
	var guard := 0
	while not look_for_combinations().is_empty() and guard < 50:
		for combo in look_for_combinations():
			for p in combo.points:
				if playable[int(p.x)][int(p.y)]:
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
	fill_random(rng)
	cells_changed.emit()


func look_for_combinations() -> Array:
	var combos: Array = []
	var checked_v := {}
	var checked_h := {}
	for x in grid_size:
		for y in grid_size:
			if not playable[x][y]:
				continue
			var t: int = cells[x][y]
			if t < 0 or blockers[x][y] == MatchPiece.Blocker.TAPE and blocker_layers[x][y] > 0:
				# Tape fully blocks matching underneath until cleared - simplify: tape cells not matchable
				if blockers[x][y] != MatchPiece.Blocker.NONE and blockers[x][y] != MatchPiece.Blocker.WRAP \
						and blockers[x][y] != MatchPiece.Blocker.SCRAP:
					if blocker_layers[x][y] > 0 and blockers[x][y] == MatchPiece.Blocker.TAPE:
						continue
			if t < 0:
				continue
			var key := Vector2i(x, y)
			if not checked_v.has(key):
				var points_v: Array[Vector2i] = []
				var k := y
				while k >= 0 and playable[x][k] and cells[x][k] == t and not _blocks_match(x, k):
					points_v.append(Vector2i(x, k))
					checked_v[Vector2i(x, k)] = true
					k -= 1
				k = y + 1
				while k < grid_size and playable[x][k] and cells[x][k] == t and not _blocks_match(x, k):
					points_v.append(Vector2i(x, k))
					checked_v[Vector2i(x, k)] = true
					k += 1
				if points_v.size() >= NB_MIN:
					combos.append({"type": t, "points": points_v})
			if not checked_h.has(key):
				var points_h: Array[Vector2i] = []
				var kx := x
				while kx >= 0 and playable[kx][y] and cells[kx][y] == t and not _blocks_match(kx, y):
					points_h.append(Vector2i(kx, y))
					checked_h[Vector2i(kx, y)] = true
					kx -= 1
				kx = x + 1
				while kx < grid_size and playable[kx][y] and cells[kx][y] == t and not _blocks_match(kx, y):
					points_h.append(Vector2i(kx, y))
					checked_h[Vector2i(kx, y)] = true
					kx += 1
				if points_h.size() >= NB_MIN:
					combos.append({"type": t, "points": points_h})
	return _merge_combinations(combos)


func _blocks_match(x: int, y: int) -> bool:
	var b: int = blockers[x][y]
	if b == MatchPiece.Blocker.TAPE and blocker_layers[x][y] > 0:
		return true
	if b == MatchPiece.Blocker.HONEY and blocker_layers[x][y] > 0:
		return false ## honey: can match inside
	if b == MatchPiece.Blocker.CAKE or b == MatchPiece.Blocker.CHEST or b == MatchPiece.Blocker.FOUNTAIN:
		return true
	return false


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


func tile_fall() -> Array:
	var result: Array = []
	for x in grid_size:
		for y in grid_size:
			if not playable[x][y] or cells[x][y] >= 0:
				continue
			var k := y + 1
			while k < grid_size:
				if playable[x][k] and cells[x][k] >= 0 and not _immovable(x, k):
					var fall_height := k - y
					while k < grid_size:
						if playable[x][k] and cells[x][k] >= 0 and not _immovable(x, k):
							result.append({"x": x, "from_y": k, "to_y": k - fall_height})
						elif not playable[x][k] or cells[x][k] < 0:
							fall_height += 1
						k += 1
					break
				k += 1
			break
	return result


func _immovable(x: int, y: int) -> bool:
	var b: int = blockers[x][y]
	return b == MatchPiece.Blocker.TAPE or b == MatchPiece.Blocker.CAKE \
			or b == MatchPiece.Blocker.CHEST or b == MatchPiece.Blocker.FOUNTAIN


func apply_falls(falls: Array) -> void:
	var by_col := {}
	for f in falls:
		var x: int = f.x
		if not by_col.has(x):
			by_col[x] = []
		by_col[x].append(f)
	for x in by_col.keys():
		var list: Array = by_col[x]
		list.sort_custom(func(a, b): return a.to_y < b.to_y)
		var moves: Array = []
		for f in list:
			moves.append({
				"to": f.to_y,
				"color": cells[x][f.from_y],
				"special": specials[x][f.from_y],
				"blocker": blockers[x][f.from_y],
				"blocker_layers": blocker_layers[x][f.from_y],
			})
		for f in list:
			cells[x][f.from_y] = -1
			specials[x][f.from_y] = MatchPiece.Special.NONE
			blockers[x][f.from_y] = MatchPiece.Blocker.NONE
			blocker_layers[x][f.from_y] = 0
		for m in moves:
			cells[x][m.to] = m.color
			specials[x][m.to] = m.special
			blockers[x][m.to] = m.blocker
			blocker_layers[x][m.to] = m.blocker_layers
	cells_changed.emit()


func remove_points(points: Array) -> void:
	for p in points:
		var x := int(p.x)
		var y := int(p.y)
		if not is_playable(x, y):
			continue
		# Damage tape first
		if blockers[x][y] == MatchPiece.Blocker.TAPE and blocker_layers[x][y] > 0:
			blocker_layers[x][y] -= 1
			if blocker_layers[x][y] <= 0:
				blockers[x][y] = MatchPiece.Blocker.NONE
			continue
		if blockers[x][y] == MatchPiece.Blocker.WRAP and blocker_layers[x][y] > 0:
			blocker_layers[x][y] = 0
			blockers[x][y] = MatchPiece.Blocker.NONE
			continue
		cells[x][y] = -1
		specials[x][y] = MatchPiece.Special.NONE
		if blockers[x][y] == MatchPiece.Blocker.SCRAP:
			blockers[x][y] = MatchPiece.Blocker.NONE
			blocker_layers[x][y] = 0
		if stickers[x][y] > 0:
			stickers[x][y] -= 1
	cells_changed.emit()


func swap_cells(a: Vector2i, b: Vector2i) -> void:
	var tmp_c = cells[a.x][a.y]
	var tmp_s = specials[a.x][a.y]
	var tmp_b = blockers[a.x][a.y]
	var tmp_bl = blocker_layers[a.x][a.y]
	cells[a.x][a.y] = cells[b.x][b.y]
	specials[a.x][a.y] = specials[b.x][b.y]
	blockers[a.x][a.y] = blockers[b.x][b.y]
	blocker_layers[a.x][a.y] = blocker_layers[b.x][b.y]
	cells[b.x][b.y] = tmp_c
	specials[b.x][b.y] = tmp_s
	blockers[b.x][b.y] = tmp_b
	blocker_layers[b.x][b.y] = tmp_bl
	cells_changed.emit()


func would_swap_match(a: Vector2i, b: Vector2i) -> bool:
	if not is_playable(a.x, a.y) or not is_playable(b.x, b.y):
		return false
	if abs(a.x - b.x) + abs(a.y - b.y) != 1:
		return false
	# Specials may always swap to activate
	if get_special(a.x, a.y) != MatchPiece.Special.NONE and get_special(b.x, b.y) != MatchPiece.Special.NONE:
		return true
	if get_special(a.x, a.y) == MatchPiece.Special.BOMB or get_special(b.x, b.y) == MatchPiece.Special.BOMB:
		return true
	swap_cells(a, b)
	var ok := not look_for_combinations().is_empty()
	swap_cells(a, b)
	return ok


func new_combi_on_switch(x: int, y: int) -> bool:
	if is_playable(x + 1, y) and cells[x + 1][y] >= 0 and cells[x][y] >= 0:
		swap_cells(Vector2i(x, y), Vector2i(x + 1, y))
		var ok_r := not look_for_combinations().is_empty()
		swap_cells(Vector2i(x, y), Vector2i(x + 1, y))
		if ok_r:
			return true
	if is_playable(x, y + 1) and cells[x][y + 1] >= 0 and cells[x][y] >= 0:
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
			if cells[x][y] < 0 or not playable[x][y]:
				continue
			if new_combi_on_switch(x, y):
				return true
	return false


func fill_blanks(rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var spawned: Array = []
	for x in grid_size:
		for y in grid_size:
			if not playable[x][y]:
				continue
			if cells[x][y] < 0 and not _immovable(x, y):
				cells[x][y] = rng.randi_range(0, type_count - 1)
				specials[x][y] = MatchPiece.Special.NONE
				spawned.append(Vector2i(x, y))
	cells_changed.emit()
	return spawned


func find_hint() -> Array:
	for x in grid_size:
		for y in grid_size:
			if cells[x][y] < 0 or not playable[x][y]:
				continue
			for n in [Vector2i(x + 1, y), Vector2i(x, y + 1)]:
				if not is_playable(n.x, n.y):
					continue
				if would_swap_match(Vector2i(x, y), n):
					return [Vector2i(x, y), n]
	return []


func count_stickers() -> int:
	var n := 0
	for x in grid_size:
		for y in grid_size:
			n += int(stickers[x][y])
	return n


func to_dict() -> Dictionary:
	var flat: Array = []
	var flat_s: Array = []
	var flat_b: Array = []
	var flat_bl: Array = []
	var flat_st: Array = []
	var flat_p: Array = []
	for x in grid_size:
		for y in grid_size:
			flat.append(cells[x][y])
			flat_s.append(specials[x][y])
			flat_b.append(blockers[x][y])
			flat_bl.append(blocker_layers[x][y])
			flat_st.append(stickers[x][y])
			flat_p.append(playable[x][y])
	return {
		"grid_size": grid_size,
		"type_count": type_count,
		"cells": flat,
		"specials": flat_s,
		"blockers": flat_b,
		"blocker_layers": flat_bl,
		"stickers": flat_st,
		"playable": flat_p,
	}


func from_dict(data: Dictionary) -> void:
	grid_size = int(data.get("grid_size", 8))
	type_count = int(data.get("type_count", grid_size))
	clear()
	var flat: Array = data.get("cells", [])
	var flat_s: Array = data.get("specials", [])
	var flat_b: Array = data.get("blockers", [])
	var flat_bl: Array = data.get("blocker_layers", [])
	var flat_st: Array = data.get("stickers", [])
	var flat_p: Array = data.get("playable", [])
	var idx := 0
	for x in grid_size:
		for y in grid_size:
			if idx < flat.size():
				cells[x][y] = int(flat[idx])
			if idx < flat_s.size():
				specials[x][y] = int(flat_s[idx])
			if idx < flat_b.size():
				blockers[x][y] = int(flat_b[idx])
			if idx < flat_bl.size():
				blocker_layers[x][y] = int(flat_bl[idx])
			if idx < flat_st.size():
				stickers[x][y] = int(flat_st[idx])
			if idx < flat_p.size():
				playable[x][y] = bool(flat_p[idx])
			idx += 1
	cells_changed.emit()
