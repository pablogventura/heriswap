class_name DailyDesk
extends RefCounted

## One free daily quest seed based on UTC date.


static func today_key() -> String:
	var t := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [int(t.year), int(t.month), int(t.day)]


static func level_for_today() -> Dictionary:
	var pack := LevelCatalog.load_pack()
	if pack.is_empty():
		return {}
	var key := today_key()
	var h := 0
	for i in key.length():
		h = (h * 33 + key.unicode_at(i)) % 997
	var lv: Dictionary = pack[h % pack.size()].duplicate(true)
	lv["id"] = "daily_%s" % key
	lv["daily"] = true
	return lv


static func already_claimed(save: Dictionary) -> bool:
	return str(save.get("daily_claimed", "")) == today_key()


static func mark_claimed(save: Dictionary) -> void:
	save["daily_claimed"] = today_key()
