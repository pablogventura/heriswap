extends RefCounted


static func run() -> int:
	var failed := 0
	var backup := SaveService.load_scores()
	SaveService._write_json(SaveService.SCORES_PATH, {"version": SaveService.SCHEMA_VERSION, "entries": []})

	failed += TestHarness.expect("empty is high", SaveService.is_high_score(0, Difficulty.EASY, 1, 0.0))

	for i in 5:
		SaveService.add_score({
			"points": (i + 1) * 1000,
			"level": 1,
			"time": 10.0,
			"name": "T%d" % i,
			"mode": 0,
			"difficulty": Difficulty.EASY,
		})
	var top := SaveService.get_top5(0, Difficulty.EASY)
	failed += TestHarness.expect("top5 size", top.size() == 5)
	failed += TestHarness.expect("top5 ordered", int(top[0].points) >= int(top[4].points))
	failed += TestHarness.expect(
		"not high under worst",
		not SaveService.is_high_score(0, Difficulty.EASY, int(top[4].points) - 1, 0.0)
	)
	failed += TestHarness.expect(
		"high beats worst",
		SaveService.is_high_score(0, Difficulty.EASY, int(top[4].points) + 1, 0.0)
	)

	SaveService._write_json(SaveService.SCORES_PATH, {"version": SaveService.SCHEMA_VERSION, "entries": []})
	for i in 5:
		SaveService.add_score({
			"points": 100,
			"level": 1,
			"time": 50.0 - float(i),
			"name": "TA%d" % i,
			"mode": 1,
			"difficulty": Difficulty.MEDIUM,
		})
	var top_t := SaveService.get_top5(1, Difficulty.MEDIUM)
	failed += TestHarness.expect("tiles top ordered", float(top_t[0].time) <= float(top_t[4].time))
	failed += TestHarness.expect(
		"tiles high better time",
		SaveService.is_high_score(1, Difficulty.MEDIUM, 100, float(top_t[4].time) - 0.5)
	)

	SaveService._write_json(SaveService.SCORES_PATH, {"version": SaveService.SCHEMA_VERSION, "entries": backup})
	return failed
