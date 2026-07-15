class_name Difficulty
extends RefCounted

## Matches original enum values (Medium=2, Hard=1 for Android score continuity).
const EASY := 0
const HARD := 1
const MEDIUM := 2

static func to_grid_size(diff: int) -> int:
	match diff:
		EASY:
			return 5
		MEDIUM:
			return 6
		_:
			return 8

static func from_grid_size(size: int) -> int:
	match size:
		5:
			return EASY
		6:
			return MEDIUM
		_:
			return HARD

static func next(diff: int) -> int:
	match diff:
		EASY:
			return MEDIUM
		MEDIUM:
			return HARD
		_:
			return EASY

static func label_key(diff: int) -> String:
	match diff:
		EASY:
			return "diff_1"
		MEDIUM:
			return "diff_2"
		_:
			return "diff_3"
