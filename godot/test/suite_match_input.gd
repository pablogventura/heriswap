extends RefCounted

## Regression: play input must not stick after juice morphs / SPAWN without timer.


static func run() -> int:
	var failed := 0
	failed += TestHarness.expect(
		"user_input phase is 0",
		MatchInputRules.PHASE_USER_INPUT == 0
	)
	failed += TestHarness.expect(
		"input ok idle",
		MatchInputRules.can_accept_play_input(MatchInputRules.PHASE_USER_INPUT, false, false)
	)
	failed += TestHarness.expect(
		"input blocked animating",
		not MatchInputRules.can_accept_play_input(MatchInputRules.PHASE_USER_INPUT, true, false)
	)
	failed += TestHarness.expect(
		"input blocked swap lock",
		not MatchInputRules.can_accept_play_input(MatchInputRules.PHASE_USER_INPUT, false, true)
	)
	failed += TestHarness.expect(
		"input blocked in SPAWN",
		not MatchInputRules.can_accept_play_input(3, false, false)
	)
	failed += TestHarness.expect(
		"input blocked in DELETE",
		not MatchInputRules.can_accept_play_input(1, false, false)
	)
	failed += TestHarness.expect(
		"input blocked PAUSED",
		not MatchInputRules.can_accept_play_input(5, false, false)
	)
	return failed
