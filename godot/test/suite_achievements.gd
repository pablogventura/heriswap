extends RefCounted


static func run() -> int:
	var failed := 0
	var snap := Achievements.to_dict()
	var unlocked_backup := Achievements.unlocked.duplicate(true)
	var l666_backup := Achievements.l666_lose
	var they_backup := Achievements.l_they_good

	Achievements.new_game(Difficulty.EASY)
	var before_easy := bool(Achievements.unlocked.get("E6InARow", false))
	Achievements.s6_in_a_row(6)
	failed += TestHarness.expect(
		"6-in-row needs hard",
		bool(Achievements.unlocked.get("E6InARow", false)) == before_easy
	)

	Achievements.new_game(Difficulty.HARD)
	Achievements.unlocked["E6InARow"] = false
	Achievements.s6_in_a_row(5)
	failed += TestHarness.expect("6-in-row under threshold", not Achievements.is_unlocked("E6InARow"))
	Achievements.s6_in_a_row(6)
	failed += TestHarness.expect("6-in-row unlocks hard", Achievements.is_unlocked("E6InARow"))

	Achievements.new_game(Difficulty.HARD)
	Achievements.unlocked["EFastAndFinish"] = false
	Achievements.s_fast_and_finish(60.0)
	failed += TestHarness.expect("fast finish too slow", not Achievements.is_unlocked("EFastAndFinish"))
	Achievements.s_fast_and_finish(50.0)
	failed += TestHarness.expect("fast finish unlocks", Achievements.is_unlocked("EFastAndFinish"))

	Achievements.new_game(Difficulty.HARD)
	Achievements.s_lucky_luke(1.5)
	Achievements.s_lucky_luke(1.5)
	failed += TestHarness.expect("lucky luke accumulator ok", Achievements.time_total_played >= 2.9)
	Achievements.s_lucky_luke(3.0)
	failed += TestHarness.approx("lucky luke reset on slow", Achievements.time_total_played, 0.0)

	Achievements.new_game(Difficulty.HARD)
	Achievements.unlocked["EWhatToDo"] = false
	Achievements.s_what_to_do(true, 2.0)
	failed += TestHarness.expect("what to do not yet", not Achievements.what_to_do_done)
	Achievements.s_what_to_do(true, 4.0)
	failed += TestHarness.expect("what to do unlocks", Achievements.what_to_do_done)

	Achievements.new_game(Difficulty.HARD)
	Achievements.unlocked["E666Loser"] = false
	Achievements.l666_lose = 0
	Achievements.s_666_loser(6)
	Achievements.s_666_loser(6)
	Achievements.s_666_loser(5)
	failed += TestHarness.expect("666 reset off level", Achievements.l666_lose == 0)
	Achievements.s_666_loser(6)
	Achievements.s_666_loser(6)
	Achievements.s_666_loser(6)
	failed += TestHarness.expect("666 unlocks", Achievements.is_unlocked("E666Loser"))

	Achievements.unlocked["EBimBamBoum"] = false
	Achievements.s_bim_bam_boum(3)
	failed += TestHarness.expect("bim bamboum", Achievements.is_unlocked("EBimBamBoum"))

	Achievements.from_dict(snap)
	Achievements.unlocked = unlocked_backup
	Achievements.l666_lose = l666_backup
	Achievements.l_they_good = they_backup
	Achievements._persist()
	return failed
