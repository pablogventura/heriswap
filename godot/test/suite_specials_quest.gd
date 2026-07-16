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
	g.set_size(6, 5)
	failed += TestHarness.expect("size 6", g.grid_size == 6)
	failed += TestHarness.expect("types 5", g.type_count == 5)
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

	return failed
