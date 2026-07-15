class_name MatchInputRules
extends RefCounted

## Shared play-input gate (kept free of autoloads for headless tests).
## Must stay aligned with MatchRoot.Phase.USER_INPUT == 0.

const PHASE_USER_INPUT := 0


static func can_accept_play_input(phase: int, animating: bool, swap_locked: bool) -> bool:
	return phase == PHASE_USER_INPUT and not animating and not swap_locked
