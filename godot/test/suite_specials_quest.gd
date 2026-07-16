extends RefCounted


static func run() -> int:
	var failed := 0
	# Specials classification
	var line4: Array = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	failed += TestHarness.expect("stripe h", MatchSpecials.classify_combo(line4) == MatchPiece.Special.STRIPE_H)
	var line5: Array = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)]
	failed += TestHarness.expect("bomb", MatchSpecials.classify_combo(line5) == MatchPiece.Special.BOMB)
	var sq: Array = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	failed += TestHarness.expect("fish", MatchSpecials.classify_combo(sq) == MatchPiece.Special.FISH)

	var g := GridModel.new()
	g.set_size(6, 6)
	failed += TestHarness.expect("size 6", g.grid_size == 6)
	failed += TestHarness.expect("types 6", g.type_count == 6)
	g.fill_until_playable()
	failed += TestHarness.expect("playable moves", g.still_combinations())

	g.clear()
	g.set_cell(0, 0, 1)
	g.set_cell(1, 0, 1)
	g.set_cell(2, 0, 1)
	g.set_cell(3, 0, 1)
	g.set_special(1, 0, MatchPiece.Special.STRIPE_H)
	var act := MatchSpecials.activation_cells(g, Vector2i(1, 0), MatchPiece.Special.STRIPE_H)
	failed += TestHarness.expect("stripe clears row", act.size() == g.grid_size)

	g.set_sticker(2, 2, 2)
	failed += TestHarness.expect("sticker count", g.count_stickers() == 2)
	g.remove_points([Vector2i(2, 2)])
	failed += TestHarness.expect("sticker damaged", g.count_stickers() == 1)

	var qm := QuestMode.new()
	qm.apply_level_def({"objective": "clear_stickers", "moves": 10})
	qm.sticky_start = 3
	qm.sync_stickers(g)
	failed += TestHarness.expect("quest moves", qm.moves_left == 10)
	qm.spend_move()
	failed += TestHarness.expect("spent move", qm.moves_left == 9)

	var pack_errs := LevelValidator.validate_pack()
	failed += TestHarness.expect("level pack valid", pack_errs.is_empty())

	var def := LevelCatalog.get_level("q001")
	failed += TestHarness.expect("catalog q001", str(def.get("id", "")) == "q001")
	var g2 := GridModel.new()
	LevelCatalog.apply_to_grid(g2, def)
	failed += TestHarness.expect("quest stickers applied", g2.count_stickers() > 0)

	# Irregular playable mask (Candy-style holes)
	var g3 := GridModel.new()
	g3.set_size(6, 6)
	var mask: Array = []
	for x in 6:
		var col: Array = []
		for y in 6:
			var on := not ((x == 0 or x == 5) and (y == 0 or y == 5)) and not (x >= 2 and x <= 3 and y >= 2 and y <= 3)
			col.append(on)
		mask.append(col)
	g3.set_playable_mask(mask)
	failed += TestHarness.expect("mask corner off", not g3.is_playable(0, 0))
	failed += TestHarness.expect("mask hole off", not g3.is_playable(2, 2))
	failed += TestHarness.expect("mask center playable", g3.is_playable(1, 1))
	g3.fill_until_playable()
	failed += TestHarness.expect("mask hole stays empty", g3.get_cell(2, 2) < 0)

	var q8 := LevelCatalog.get_level("q008")
	failed += TestHarness.expect("q008 has mask", typeof(q8.get("mask", null)) == TYPE_ARRAY)
	var g4 := GridModel.new()
	LevelCatalog.apply_to_grid(g4, q8)
	failed += TestHarness.expect("q008 corner unplayable", not g4.is_playable(0, 0))

	return failed
