extends RefCounted


static func run() -> int:
	var failed := 0
	var easy := TimingConfig.for_difficulty(Difficulty.EASY)
	var medium := TimingConfig.for_difficulty(Difficulty.MEDIUM)
	var hard := TimingConfig.for_difficulty(Difficulty.HARD)
	failed += TestHarness.expect("hard faster delete", hard.deletion < easy.deletion)
	failed += TestHarness.expect("hard faster fall", hard.fall < easy.fall)
	failed += TestHarness.expect("hard faster spawn", hard.spawn < easy.spawn)
	failed += TestHarness.expect("hard faster swap", hard.swap < easy.swap)
	failed += TestHarness.expect("medium between delete", medium.deletion < easy.deletion and medium.deletion > hard.deletion)
	failed += TestHarness.expect("easy level_changed longer", easy.level_changed >= medium.level_changed)
	failed += TestHarness.expect("swap positive", easy.swap > 0.0 and hard.swap > 0.0)
	return failed
