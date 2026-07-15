class_name TimingConfig
extends RefCounted

## Ported from HeriswapGame difficulty timings (delete/fall/spawn scaled).

var deletion: float = 0.35
var fall: float = 0.25
var spawn: float = 0.2
var swap: float = 0.2
var level_changed: float = 1.6


static func for_difficulty(diff: int) -> TimingConfig:
	var t := TimingConfig.new()
	match diff:
		Difficulty.EASY:
			t.deletion = 0.45
			t.fall = 0.35
			t.spawn = 0.28
			t.swap = 0.28
			t.level_changed = 2.4
		Difficulty.MEDIUM:
			t.deletion = 0.35
			t.fall = 0.25
			t.spawn = 0.2
			t.swap = 0.22
			t.level_changed = 2.0
		_:
			t.deletion = 0.22
			t.fall = 0.16
			t.spawn = 0.12
			t.swap = 0.15
			t.level_changed = 1.5
	return t
