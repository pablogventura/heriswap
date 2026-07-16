extends RefCounted


static func run() -> int:
	var failed := 0
	failed += TestHarness.expect("easy size", Difficulty.to_grid_size(Difficulty.EASY) == 5)
	failed += TestHarness.expect("medium size", Difficulty.to_grid_size(Difficulty.MEDIUM) == 6)
	failed += TestHarness.expect("hard size", Difficulty.to_grid_size(Difficulty.HARD) == 8)
	failed += TestHarness.expect("easy types cc", Difficulty.to_type_count(Difficulty.EASY) == 6)
	failed += TestHarness.expect("medium types", Difficulty.to_type_count(Difficulty.MEDIUM) == 6)
	failed += TestHarness.expect("hard types", Difficulty.to_type_count(Difficulty.HARD) == 8)
	failed += TestHarness.expect("diff next wraps", Difficulty.next(Difficulty.HARD) == Difficulty.EASY)

	var g := GridModel.new()
	g.set_difficulty(Difficulty.EASY)
	failed += TestHarness.expect("easy grid types", g.type_count == 6)
	failed += TestHarness.expect("clear empty", g.get_cell(0, 0) == -1)

	g.clear()
	g.set_cell(0, 0, 1)
	g.set_cell(1, 0, 1)
	g.set_cell(2, 0, 1)
	g.set_cell(3, 0, 2)
	var combos := g.look_for_combinations()
	failed += TestHarness.expect("h match found", combos.size() == 1)
	failed += TestHarness.expect("h match len", combos[0].points.size() == 3)

	g.clear()
	g.set_cell(0, 0, 2)
	g.set_cell(0, 1, 2)
	g.set_cell(0, 2, 2)
	combos = g.look_for_combinations()
	failed += TestHarness.expect("v match found", combos.size() >= 1)

	g.clear()
	g.set_cell(0, 2, 3)
	g.set_cell(0, 0, -1)
	g.set_cell(0, 1, -1)
	var falls := g.tile_fall()
	failed += TestHarness.expect("fall exists", falls.size() >= 1)
	g.apply_falls(falls)
	failed += TestHarness.expect("fell to bottom", g.get_cell(0, 0) == 3)

	g.clear()
	g.set_cell(0, 0, 1)
	g.set_cell(1, 0, 2)
	g.set_cell(2, 0, 1)
	g.set_cell(1, 1, 1)
	failed += TestHarness.expect("swap would match", g.would_swap_match(Vector2i(1, 0), Vector2i(1, 1)))

	g.clear()
	g.set_cell(0, 0, 1)
	g.set_cell(1, 0, 2)
	failed += TestHarness.expect("swap no match", not g.would_swap_match(Vector2i(0, 0), Vector2i(1, 0)))

	g.set_difficulty(Difficulty.MEDIUM)
	g.fill_until_playable()
	failed += TestHarness.expect("still has moves", g.still_combinations())

	var spawned := g.fill_blanks()
	failed += TestHarness.expect("fill blanks empty when full", spawned.is_empty())

	g.clear()
	g.set_cell(0, 0, -1)
	spawned = g.fill_blanks()
	failed += TestHarness.expect("fill blanks spawns", spawned.size() >= 1)
	failed += TestHarness.expect("spawn cell filled", g.get_cell(0, 0) >= 0)

	var d := g.to_dict()
	var g2 := GridModel.new()
	g2.from_dict(d)
	failed += TestHarness.expect("grid dict roundtrip size", g2.grid_size == g.grid_size)
	failed += TestHarness.expect("grid dict roundtrip cell", g2.get_cell(0, 0) == g.get_cell(0, 0))

	var n := NormalMode.new()
	n.enter(Difficulty.HARD, 1)
	n.score_calc(3, n.bonus_type, g)
	failed += TestHarness.expect("normal scored", n.points > 0)

	var t := TilesAttackMode.new()
	t.enter(Difficulty.EASY, 1)
	t.score_calc(5, 0, g)
	failed += TestHarness.expect("tiles progress", t.leaves_done >= 5)

	var g100 := Go100SecondsMode.new()
	g100.enter(Difficulty.HARD, 1)
	g100.score_calc(3, 0, g)
	failed += TestHarness.expect("100 scored", g100.points > 0)

	failed += TestHarness.expect(
		"branch delete helper",
		NormalMode.level_to_leave_to_delete(3, 5, 0, 6) >= 0
	)
	return failed
