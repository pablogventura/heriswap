class_name MatchDecor
extends Node2D

var _scroll: float = 0.0
var _decor1: Sprite2D
var _decor2: Sprite2D
var _clouds: Array = []


func _ready() -> void:
	# Full-bleed craft sky / desk backdrop (avoid empty ColorRect-only look).
	var bg := Sprite2D.new()
	bg.name = "MatchBg"
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.z_index = -30
	var bg_paths := [
		"res://assets/textures/menu/match_bg.png",
		"res://assets/textures/menu/back.png",
	]
	for path in bg_paths:
		if ResourceLoader.exists(path):
			bg.texture = load(path)
			break
	if bg.texture:
		var tex_size: Vector2 = bg.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			bg.scale = Vector2(800.0 / tex_size.x, 1280.0 / tex_size.y)
	else:
		var fallback := ColorRect.new()
		fallback.size = Vector2(800, 1280)
		fallback.color = Color(0.72, 0.84, 0.92, 1)
		fallback.z_index = -30
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fallback)
	add_child(bg)

	_decor2 = _make_sprite([
		"res://assets/textures/decor2/decor2nd_0.png",
		"res://assets/textures/decor2/2emeplan.png",
	], Vector2(400, 880), 2.1)
	_decor1 = _make_sprite([
		"res://assets/textures/decor1/decor1er_0.png",
		"res://assets/textures/decor1/decor1er_1.png",
	], Vector2(400, 1080), 2.3)
	for i in 4:
		var c := _make_sprite([
			"res://assets/textures/nuages/haut_0.png",
			"res://assets/textures/nuages/moyen_0.png",
			"res://assets/textures/nuages/bas_0.png",
		], Vector2(80.0 + i * 200.0, 90.0 + (i % 3) * 50.0), 1.15)
		if c.texture:
			_clouds.append(c)


func _make_sprite(paths: Array, pos: Vector2, scl: float) -> Sprite2D:
	var s := Sprite2D.new()
	for path in paths:
		if ResourceLoader.exists(path):
			s.texture = load(path)
			break
	s.centered = true
	s.position = pos
	s.scale = Vector2(scl, scl)
	s.z_index = -10
	add_child(s)
	return s


func scroll(delta: float, speed: float) -> void:
	_scroll += delta * speed
	if _decor1 and _decor1.texture:
		_decor1.position.x = 400.0 + sin(_scroll) * 30.0
	if _decor2 and _decor2.texture:
		_decor2.position.x = 400.0 + cos(_scroll * 0.7) * 20.0
	for i in _clouds.size():
		var c: Sprite2D = _clouds[i]
		c.position.x = fmod(c.position.x + delta * (12.0 + i * 6.0) + 900.0, 900.0) - 50.0
