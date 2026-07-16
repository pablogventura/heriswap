class_name MatchSpecials
extends RefCounted

## Create / activate paper specials (rayado, paquete, confetti, avioncito).


static func classify_combo(points: Array) -> int:
	## Returns MatchPiece.Special to spawn when clearing this combo (or NONE).
	if points.size() < 4:
		return MatchPiece.Special.NONE
	var xs := {}
	var ys := {}
	for p in points:
		xs[int(p.x)] = true
		ys[int(p.y)] = true
	# 2x2 square -> fish / paper plane
	if points.size() == 4 and xs.size() == 2 and ys.size() == 2:
		return MatchPiece.Special.FISH
	# Straight line of 5+ -> bomb
	if (xs.size() == 1 or ys.size() == 1) and points.size() >= 5:
		return MatchPiece.Special.BOMB
	# Straight 4 -> stripe oriented along the line
	if xs.size() == 1 and points.size() >= 4:
		return MatchPiece.Special.STRIPE_V
	if ys.size() == 1 and points.size() >= 4:
		return MatchPiece.Special.STRIPE_H
	# L / T (multiple rows and cols, size >= 5 typically after merge) -> wrapped
	if xs.size() >= 2 and ys.size() >= 2 and points.size() >= 5:
		return MatchPiece.Special.WRAPPED
	if xs.size() >= 2 and ys.size() >= 2 and points.size() >= 4:
		# T/L sometimes merge to 5; 4 in bent shape rare - treat 5+ only for wrapped
		pass
	return MatchPiece.Special.NONE


static func centroid(points: Array) -> Vector2i:
	if points.is_empty():
		return Vector2i.ZERO
	var sx := 0
	var sy := 0
	for p in points:
		sx += int(p.x)
		sy += int(p.y)
	return Vector2i(sx / points.size(), sy / points.size())


static func activation_cells(grid: GridModel, at: Vector2i, special: int, color_hint: int = -1) -> Array:
	## Cells damaged/cleared by activating a special at `at`.
	var out: Array = []
	var seen := {}
	var add := func(p: Vector2i):
		if not grid.is_playable(p.x, p.y):
			return
		var k := p
		if seen.has(k):
			return
		seen[k] = true
		out.append(p)

	match special:
		MatchPiece.Special.STRIPE_H:
			for x in grid.grid_size:
				add.call(Vector2i(x, at.y))
		MatchPiece.Special.STRIPE_V:
			for y in grid.grid_size:
				add.call(Vector2i(at.x, y))
		MatchPiece.Special.WRAPPED:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					add.call(Vector2i(at.x + dx, at.y + dy))
		MatchPiece.Special.BOMB:
			var c := color_hint
			if c < 0:
				c = grid.get_cell(at.x, at.y)
			for x in grid.grid_size:
				for y in grid.grid_size:
					if grid.get_cell(x, y) == c:
						add.call(Vector2i(x, y))
			add.call(at)
		MatchPiece.Special.FISH:
			# Three priority sticker cells then random filled
			var stickers: Array = []
			var filled: Array = []
			for x in grid.grid_size:
				for y in grid.grid_size:
					if not grid.is_playable(x, y):
						continue
					if grid.get_sticker(x, y) > 0:
						stickers.append(Vector2i(x, y))
					elif grid.get_cell(x, y) >= 0:
						filled.append(Vector2i(x, y))
			stickers.shuffle()
			filled.shuffle()
			var picks: Array = []
			for p in stickers:
				if picks.size() >= 3:
					break
				picks.append(p)
			for p in filled:
				if picks.size() >= 3:
					break
				picks.append(p)
			for p in picks:
				add.call(p)
		_:
			add.call(at)
	return out


static func combo_activation(grid: GridModel, a: Vector2i, b: Vector2i) -> Array:
	## Swap of two specials -> union of effects (simplified CCS-like).
	var sa := grid.get_special(a.x, a.y)
	var sb := grid.get_special(b.x, b.y)
	if sa == MatchPiece.Special.NONE and sb == MatchPiece.Special.NONE:
		return []
	var cells: Array = []
	var seen := {}
	var merge := func(arr: Array):
		for p in arr:
			if seen.has(p):
				continue
			seen[p] = true
			cells.append(p)
	# Bomb + bomb / bomb + anything big clear
	if sa == MatchPiece.Special.BOMB and sb == MatchPiece.Special.BOMB:
		for x in grid.grid_size:
			for y in grid.grid_size:
				if grid.is_playable(x, y) and grid.get_cell(x, y) >= 0:
					merge.call([Vector2i(x, y)])
		return cells
	if sa == MatchPiece.Special.BOMB:
		merge.call(activation_cells(grid, b, MatchPiece.Special.BOMB, grid.get_cell(b.x, b.y)))
		merge.call(activation_cells(grid, a, sb if sb != MatchPiece.Special.NONE else MatchPiece.Special.BOMB, grid.get_cell(a.x, a.y)))
		return cells
	if sb == MatchPiece.Special.BOMB:
		merge.call(activation_cells(grid, a, MatchPiece.Special.BOMB, grid.get_cell(a.x, a.y)))
		merge.call(activation_cells(grid, b, sa, grid.get_cell(b.x, b.y)))
		return cells
	# Stripe + stripe -> cross
	if (sa == MatchPiece.Special.STRIPE_H or sa == MatchPiece.Special.STRIPE_V) \
			and (sb == MatchPiece.Special.STRIPE_H or sb == MatchPiece.Special.STRIPE_V):
		merge.call(activation_cells(grid, a, MatchPiece.Special.STRIPE_H))
		merge.call(activation_cells(grid, a, MatchPiece.Special.STRIPE_V))
		return cells
	# Stripe + wrapped -> big cross-ish
	if (sa == MatchPiece.Special.WRAPPED and (sb == MatchPiece.Special.STRIPE_H or sb == MatchPiece.Special.STRIPE_V)) \
			or (sb == MatchPiece.Special.WRAPPED and (sa == MatchPiece.Special.STRIPE_H or sa == MatchPiece.Special.STRIPE_V)):
		merge.call(activation_cells(grid, a, MatchPiece.Special.STRIPE_H))
		merge.call(activation_cells(grid, a, MatchPiece.Special.STRIPE_V))
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				merge.call([Vector2i(a.x + dx, a.y + dy)])
		return cells
	merge.call(activation_cells(grid, a, sa, grid.get_cell(a.x, a.y)))
	merge.call(activation_cells(grid, b, sb, grid.get_cell(b.x, b.y)))
	return cells
