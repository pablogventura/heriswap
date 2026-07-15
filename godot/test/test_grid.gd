extends SceneTree

## Headless grid unit tests: godot --headless -s res://test/test_grid.gd


func _init() -> void:
	var failed := 0
	failed += _expect("easy size", Difficulty.to_grid_size(Difficulty.EASY) == 5)
	failed += _expect("medium size", Difficulty.to_grid_size(Difficulty.MEDIUM) == 6)
	failed += _expect("hard size", Difficulty.to_grid_size(Difficulty.HARD) == 8)

	var g := GridModel.new()
	g.set_difficulty(Difficulty.EASY)
	failed += _expect("clear empty", g.get_cell(0, 0) == -1)

	# Horizontal match of 3
	g.clear()
	g.set_cell(0, 0, 1)
	g.set_cell(1, 0, 1)
	g.set_cell(2, 0, 1)
	g.set_cell(3, 0, 2)
	var combos := g.look_for_combinations()
	failed += _expect("h match found", combos.size() == 1)
	failed += _expect("h match len", combos[0].points.size() == 3)

	# Vertical match
	g.clear()
	g.set_cell(0, 0, 2)
	g.set_cell(0, 1, 2)
	g.set_cell(0, 2, 2)
	combos = g.look_for_combinations()
	failed += _expect("v match found", combos.size() >= 1)

	# Fall
	g.clear()
	g.set_cell(0, 2, 3)
	g.set_cell(0, 0, -1)
	g.set_cell(0, 1, -1)
	var falls := g.tile_fall()
	failed += _expect("fall exists", falls.size() >= 1)
	g.apply_falls(falls)
	failed += _expect("fell to bottom", g.get_cell(0, 0) == 3)

	# Swap creates match
	g.clear()
	g.set_cell(0, 0, 1)
	g.set_cell(1, 0, 2)
	g.set_cell(2, 0, 1)
	g.set_cell(1, 1, 1)
	failed += _expect("swap would match", g.would_swap_match(Vector2i(1, 0), Vector2i(1, 1)))

	# No match swap
	g.clear()
	g.set_cell(0, 0, 1)
	g.set_cell(1, 0, 2)
	failed += _expect("swap no match", not g.would_swap_match(Vector2i(0, 0), Vector2i(1, 0)))

	# Fill playable
	g.set_difficulty(Difficulty.MEDIUM)
	g.fill_until_playable()
	failed += _expect("still has moves", g.still_combinations())

	# Scoring stubs
	var n := NormalMode.new()
	n.enter(Difficulty.HARD, 1)
	n.score_calc(3, n.bonus_type, g)
	failed += _expect("normal scored", n.points > 0)

	var t := TilesAttackMode.new()
	t.enter(Difficulty.EASY, 1)
	t.score_calc(5, 0, g)
	failed += _expect("tiles progress", t.leaves_done >= 5)

	var g100 := Go100SecondsMode.new()
	g100.enter(Difficulty.HARD, 1)
	g100.score_calc(3, 0, g)
	failed += _expect("100 scored", g100.points > 0)

	if failed == 0:
		print("TEST_GRID_OK")
		quit(0)
	else:
		print("TEST_GRID_FAILED count=", failed)
		quit(1)


func _expect(label: String, cond: bool) -> int:
	if cond:
		print("OK ", label)
		return 0
	print("FAIL ", label)
	return 1
