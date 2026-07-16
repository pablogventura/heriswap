class_name TimingConfig
extends RefCounted

## Ported from HeriswapGame difficulty timings (delete/fall/spawn scaled).
## Clear = telegraph (mark what dies) + destruction (pop/explode).

var telegraph: float = 0.10
var deletion: float = 0.35 ## destroy morph duration after telegraph
var fall: float = 0.25
var spawn: float = 0.2
var swap: float = 0.2
var level_changed: float = 1.6


func clear_total() -> float:
	return telegraph + deletion


static func for_difficulty(diff: int) -> TimingConfig:
	var t := TimingConfig.new()
	match diff:
		Difficulty.EASY:
			t.telegraph = 0.12
			t.deletion = 0.33
			t.fall = 0.35
			t.spawn = 0.28
			t.swap = 0.28
			t.level_changed = 2.4
		Difficulty.MEDIUM:
			t.telegraph = 0.10
			t.deletion = 0.25
			t.fall = 0.25
			t.spawn = 0.2
			t.swap = 0.22
			t.level_changed = 2.0
		_:
			t.telegraph = 0.08
			t.deletion = 0.14
			t.fall = 0.16
			t.spawn = 0.12
			t.swap = 0.15
			t.level_changed = 1.5
	return t
