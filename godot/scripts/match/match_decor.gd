class_name MatchDecor
extends Node2D

## Layered craft backdrop with ambient drift and juice-reactive parallax punch.

const DEPTH_BG := 0.2
const DEPTH_CLOUD := 0.4
const DEPTH_DECOR2 := 0.65
const DEPTH_DECOR1 := 1.0

var _scroll: float = 0.0
var _bg: Node
var _decor1: Sprite2D
var _decor2: Sprite2D
var _clouds: Array = []
var _home_bg: Vector2 = Vector2.ZERO
var _home_decor1: Vector2 = Vector2(400, 1080)
var _home_decor2: Vector2 = Vector2(400, 880)
var _cloud_base_x: Array = []
var _cloud_base_y: Array = []
var _punch_offset: Vector2 = Vector2.ZERO
var _punch_tween: Tween


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
		_bg = bg
		_home_bg = Vector2.ZERO
		add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.name = "MatchBgFallback"
		fallback.size = Vector2(800, 1280)
		fallback.color = Color(0.72, 0.84, 0.92, 1)
		fallback.z_index = -30
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg = fallback
		_home_bg = Vector2.ZERO
		add_child(fallback)

	_decor2 = _make_sprite([
		"res://assets/textures/decor2/decor2nd_0.png",
		"res://assets/textures/decor2/2emeplan.png",
	], Vector2(400, 880), 2.1, -15)
	_home_decor2 = Vector2(400, 880)
	_decor1 = _make_sprite([
		"res://assets/textures/decor1/decor1er_0.png",
		"res://assets/textures/decor1/decor1er_1.png",
	], Vector2(400, 1080), 2.3, -10)
	_home_decor1 = Vector2(400, 1080)
	for i in 4:
		var home := Vector2(80.0 + i * 200.0, 90.0 + (i % 3) * 50.0)
		var c := _make_sprite([
			"res://assets/textures/nuages/haut_0.png",
			"res://assets/textures/nuages/moyen_0.png",
			"res://assets/textures/nuages/bas_0.png",
		], home, 1.15, -20)
		if c.texture:
			_clouds.append(c)
			_cloud_base_x.append(home.x)
			_cloud_base_y.append(home.y)


func _make_sprite(paths: Array, pos: Vector2, scl: float, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	for path in paths:
		if ResourceLoader.exists(path):
			s.texture = load(path)
			break
	s.centered = true
	s.position = pos
	s.scale = Vector2(scl, scl)
	s.z_index = z
	add_child(s)
	return s


func scroll(delta: float, speed: float) -> void:
	_scroll += delta * speed
	var reduce := bool(SaveService.options.get("reduce_motion", false))
	var ambient_bg := Vector2.ZERO
	var sway1 := 0.0
	var sway2 := 0.0
	if not reduce:
		ambient_bg = Vector2(sin(_scroll * 0.55) * 10.0, cos(_scroll * 0.4) * 6.0)
		sway1 = sin(_scroll) * 24.0
		sway2 = cos(_scroll * 0.7) * 16.0
	if _bg:
		_bg.position = _home_bg + ambient_bg + _punch_offset * DEPTH_BG
	if _decor1 and _decor1.texture:
		_decor1.position = Vector2(_home_decor1.x + sway1, _home_decor1.y) + _punch_offset * DEPTH_DECOR1
	if _decor2 and _decor2.texture:
		_decor2.position = Vector2(_home_decor2.x + sway2, _home_decor2.y) + _punch_offset * DEPTH_DECOR2
	# Crawl: slightly faster than before for a livelier sky.
	for i in _clouds.size():
		var c: Sprite2D = _clouds[i]
		var drift := 0.35 + float(i) * 0.16
		if reduce:
			drift *= 0.35
		_cloud_base_x[i] = fposmod(float(_cloud_base_x[i]) + delta * drift + 50.0, 900.0) - 50.0
		c.position = Vector2(
			float(_cloud_base_x[i]) + _punch_offset.x * DEPTH_CLOUD,
			float(_cloud_base_y[i]) + _punch_offset.y * DEPTH_CLOUD
		)


func parallax_punch(strength: float = 8.0, duration: float = 0.22) -> void:
	if bool(SaveService.options.get("reduce_motion", false)):
		return
	if _punch_tween and _punch_tween.is_valid():
		_punch_tween.kill()
	var ox := randf_range(-strength, strength)
	var oy := randf_range(-strength * 0.7, strength * 0.7)
	_punch_offset = Vector2(ox, oy)
	_punch_tween = create_tween()
	_punch_tween.tween_method(_set_punch_offset, _punch_offset, Vector2.ZERO, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_punch_offset(v: Vector2) -> void:
	_punch_offset = v
