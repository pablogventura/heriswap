class_name BoosterInventory
extends RefCounted

## Free boosters unlocked by progress (no purchases).

const KIND_SCISSORS := "scissors" ## hammer
const KIND_FREE_SWAP := "free_swap"
const KIND_CONFETTI_BAG := "confetti_bag" ## UFO-like
const KIND_PLUS_MOVES := "plus_moves"

var counts := {
	KIND_SCISSORS: 3,
	KIND_FREE_SWAP: 2,
	KIND_CONFETTI_BAG: 1,
	KIND_PLUS_MOVES: 1,
}


func has(kind: String) -> bool:
	return int(counts.get(kind, 0)) > 0


func consume(kind: String) -> bool:
	if not has(kind):
		return false
	counts[kind] = int(counts[kind]) - 1
	return true


func grant(kind: String, n: int = 1) -> void:
	counts[kind] = int(counts.get(kind, 0)) + n


func to_dict() -> Dictionary:
	return counts.duplicate()


func from_dict(data: Dictionary) -> void:
	for k in counts.keys():
		if data.has(k):
			counts[k] = int(data[k])
