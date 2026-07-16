class_name LevelCatalog
extends RefCounted

const PACK_PATH := "res://data/levels/quest_pack.json"


static func load_pack() -> Array:
	if not FileAccess.file_exists(PACK_PATH):
		return _builtin_fallback()
	var f := FileAccess.open(PACK_PATH, FileAccess.READ)
	if f == null:
		return _builtin_fallback()
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return _builtin_fallback()
	var levels: Array = data.get("levels", [])
	return levels if levels.size() > 0 else _builtin_fallback()


static func get_level(id: String) -> Dictionary:
	for lv in load_pack():
		if str(lv.get("id", "")) == id:
			return lv
	var pack := load_pack()
	return pack[0] if pack.size() > 0 else {}


static func get_level_by_index(i: int) -> Dictionary:
	var pack := load_pack()
	if pack.is_empty():
		return {}
	return pack[clampi(i, 0, pack.size() - 1)]


static func apply_to_grid(grid: GridModel, def: Dictionary, rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var size := int(def.get("size", 8))
	var types := int(def.get("types", mini(size, 8)))
	grid.set_size(size, types)
	var mask = def.get("mask", def.get("playable_mask", null))
	if typeof(mask) == TYPE_ARRAY:
		grid.set_playable_mask(mask)
	grid.fill_until_playable(rng)
	var stickers = def.get("stickers", [])
	if typeof(stickers) == TYPE_ARRAY and stickers.size() > 0:
		for s in stickers:
			var x := int(s.get("x", 0))
			var y := int(s.get("y", 0))
			var layers := int(s.get("layers", 1))
			grid.set_sticker(x, y, layers)
	elif str(def.get("objective", "")) == "clear_stickers":
		for x in grid.grid_size:
			for y in range(0, mini(3, grid.grid_size)):
				if grid.is_playable(x, y):
					grid.set_sticker(x, y, 1)
	var blockers = def.get("blockers", [])
	if typeof(blockers) == TYPE_ARRAY:
		for b in blockers:
			grid.set_blocker(
				int(b.get("x", 0)),
				int(b.get("y", 0)),
				int(b.get("kind", MatchPiece.Blocker.TAPE)),
				int(b.get("layers", 1))
			)
	# Optional pre-placed specials / board toys (lucky scrap, frog seed)
	var specials = def.get("specials", [])
	if typeof(specials) == TYPE_ARRAY:
		for s in specials:
			var sx := int(s.get("x", 0))
			var sy := int(s.get("y", 0))
			if grid.is_playable(sx, sy):
				if s.has("color"):
					grid.set_cell(sx, sy, int(s.color))
				grid.set_special(sx, sy, int(s.get("special", MatchPiece.Special.FISH)))


static func _builtin_fallback() -> Array:
	return [
		{"id": "q001", "name": "First Stickers", "objective": "clear_stickers", "moves": 25, "size": 6, "types": 6, "tutorial": true},
		{"id": "q002", "name": "Score Craft", "objective": "reach_score", "moves": 20, "size": 7, "types": 6, "target_score": 4000},
		{"id": "q003", "name": "Tape Intro", "objective": "clear_stickers", "moves": 22, "size": 7, "types": 6,
			"blockers": [{"x": 2, "y": 2, "kind": 1, "layers": 1}, {"x": 4, "y": 2, "kind": 1, "layers": 2}]},
		{"id": "zen", "name": "Zen Desk", "objective": "zen", "zen": true, "size": 8, "types": 8, "moves": 999},
	]
