class_name ScrapCodex
extends RefCounted

## Unlocks cosmetic scrap shapes as Quest levels are cleared.

var unlocked: Dictionary = {"feuille1": true}


func unlock_for_level(level_id: String) -> void:
	unlocked[level_id] = true
	var idx := unlocked.size()
	unlocked["scrap_%d" % idx] = true


func list_unlocked() -> Array:
	return unlocked.keys()


func to_dict() -> Dictionary:
	return {"unlocked": unlocked.duplicate()}


func from_dict(data: Dictionary) -> void:
	var u = data.get("unlocked", {})
	if typeof(u) == TYPE_DICTIONARY:
		unlocked = u
