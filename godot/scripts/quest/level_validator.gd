class_name LevelValidator
extends RefCounted

## LevelDef validator for ScrapSwap quest packs.


static func validate_pack(path: String = LevelCatalog.PACK_PATH) -> Array:
	## Returns list of error strings (empty = ok).
	var errors: Array = []
	var levels := LevelCatalog.load_pack()
	if levels.is_empty():
		errors.append("pack empty")
		return errors
	var ids := {}
	for i in levels.size():
		var lv = levels[i]
		if typeof(lv) != TYPE_DICTIONARY:
			errors.append("level %d not dict" % i)
			continue
		var id := str(lv.get("id", ""))
		if id == "":
			errors.append("level %d missing id" % i)
		elif ids.has(id):
			errors.append("duplicate id %s" % id)
		else:
			ids[id] = true
		var size := int(lv.get("size", 8))
		if size < 5 or size > 9:
			errors.append("%s size out of range" % id)
		var types := int(lv.get("types", size))
		if types < 3 or types > 8:
			errors.append("%s types out of range" % id)
		var obj := str(lv.get("objective", ""))
		if obj not in ["clear_stickers", "reach_score", "ingredients", "orders", "zen"]:
			errors.append("%s bad objective %s" % [id, obj])
		if obj == "reach_score" and int(lv.get("target_score", 0)) <= 0:
			errors.append("%s reach_score without target" % id)
		if obj == "orders":
			var orders = lv.get("orders", [])
			if typeof(orders) != TYPE_ARRAY or orders.is_empty():
				errors.append("%s orders empty" % id)
		var mask = lv.get("mask", lv.get("playable_mask", null))
		if typeof(mask) == TYPE_ARRAY and mask.size() != size:
			errors.append("%s mask size mismatch" % id)
		elif typeof(mask) == TYPE_ARRAY:
			for x in mask.size():
				if typeof(mask[x]) != TYPE_ARRAY or mask[x].size() != size:
					errors.append("%s mask column %d bad" % [id, x])
					break
	return errors


static func run_cli() -> int:
	var errs := validate_pack()
	if errs.is_empty():
		print("LEVEL_VALIDATOR_OK")
		return 0
	for e in errs:
		print("LEVEL_ERROR: ", e)
	return errs.size()
