class_name MatchDecor
extends Node2D

var _scroll: float = 0.0
var _decor1: Sprite2D
var _decor2: Sprite2D
var _clouds: Array = []


func _ready() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(800, 1280)
	bg.color = Color(0.45, 0.72, 0.88, 1)
	bg.z_index = -20
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_decor2 = _make_sprite([
		"res://assets/textures/decor2/2emeplan.png",
		"res://assets/textures/menu/back.png",
	], Vector2(400, 920), 1.15)
	_decor1 = _make_sprite([
		"res://assets/textures/decor1/decor1er_0.png",
		"res://assets/textures/decor1/decor1er_1.png",
	], Vector2(400, 1050), 1.05)
	for i in 4:
		var c := _make_sprite([
			"res://assets/textures/nuages/haut_0.png",
			"res://assets/textures/nuages/moyen_0.png",
			"res://assets/textures/nuages/bas_0.png",
		], Vector2(80.0 + i * 200.0, 90.0 + (i % 3) * 50.0), 0.55)
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
