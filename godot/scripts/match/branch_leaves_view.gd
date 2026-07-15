class_name BranchLeavesView
extends Node2D

## Visual branch leaves overlay synchronized with mode remain/types.

var leaf_textures: Array = []
var sprites: Array = [] ## Dictionary {sprite, type, index}
var capacity: int = 48


func setup(textures: Array) -> void:
	leaf_textures = textures
	_clear()
	var viewport := get_viewport_rect().size
	if viewport.x < 1.0:
		viewport = Vector2(800, 1280)
	for i in mini(capacity, BranchPositions.POSITIONS.size()):
		var gimp: Vector3 = BranchPositions.POSITIONS[i]
		var mapped: Dictionary = BranchPositions.to_screen(gimp, viewport)
		var spr := Sprite2D.new()
		spr.centered = true
		spr.position = mapped.position
		spr.rotation = mapped.rotation
		spr.scale = Vector2(0.35, 0.35)
		spr.visible = false
		add_child(spr)
		sprites.append({"sprite": spr, "type": -1, "index": i})


func _clear() -> void:
	for c in get_children():
		c.queue_free()
	sprites.clear()


func generate(type_count: int, per_type: int = 6) -> void:
	var idx := 0
	for t in type_count:
		for _n in per_type:
			if idx >= sprites.size():
				return
			var item: Dictionary = sprites[idx]
			item.type = t
			var spr: Sprite2D = item.sprite
			spr.texture = leaf_textures[clampi(t, 0, leaf_textures.size() - 1)]
			spr.visible = true
			spr.modulate = Color.WHITE
			spr.scale = Vector2(0.35, 0.35)
			idx += 1
	while idx < sprites.size():
		sprites[idx].type = -1
		sprites[idx].sprite.visible = false
		idx += 1


func count_of_type(leaf_type: int) -> int:
	var n := 0
	for item in sprites:
		if int(item.type) == leaf_type and item.sprite.visible:
			n += 1
	return n


func remove_of_type(leaf_type: int, count: int) -> int:
	var removed := 0
	for item in sprites:
		if removed >= count:
			break
		if int(item.type) == leaf_type and item.sprite.visible:
			item.sprite.visible = false
			item.type = -1
			removed += 1
	return removed


func remove_any(count: int) -> int:
	var removed := 0
	for item in sprites:
		if removed >= count:
			break
		if item.sprite.visible:
			item.sprite.visible = false
			item.type = -1
			removed += 1
	return removed


func visible_count() -> int:
	var n := 0
	for item in sprites:
		if item.sprite.visible:
			n += 1
	return n


func grow_all(amount: float) -> void:
	var s := 0.35 * clampf(amount, 0.0, 1.0)
	for item in sprites:
		if item.sprite.visible:
			item.sprite.scale = Vector2(s, s)


func set_all_types(leaf_type: int) -> void:
	for item in sprites:
		if item.sprite.visible:
			item.type = leaf_type
			item.sprite.texture = leaf_textures[clampi(leaf_type, 0, leaf_textures.size() - 1)]
