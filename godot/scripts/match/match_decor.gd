class_name MatchDecor
extends Node2D

## Classroom window scene + Candy-style kraft board mat with playable holes.

const DEPTH_BG := 0.15
const DEPTH_CLOUD_FAR := 0.3
const DEPTH_CLOUD_MID := 0.45
const DEPTH_DESK := 0.55
const DEPTH_FRAME := 0.25
const DEPTH_NEAR := 0.9
const VIEW_W := 800.0
const CLOUD_EDGE_FADE := 90.0

const KRAFT := Color(0.82, 0.68, 0.48, 1.0)
const CARDBOARD := Color(0.55, 0.38, 0.22, 1.0)
const TAPE := Color(0.92, 0.84, 0.55, 0.92)
const DESK := Color(0.42, 0.28, 0.16, 1.0)

var _scroll: float = 0.0
var _bg: Node
var _desk: ColorRect
var _desk_side_l: ColorRect
var _desk_side_r: ColorRect
var _decor1: Sprite2D
var _decor2: Sprite2D
var _clouds_far: Array = []
var _clouds_mid: Array = []
var _cloud_base_x: Array = []
var _cloud_base_y: Array = []
var _cloud_speeds: Array = []
var _cloud_depths: Array = []
var _home_bg: Vector2 = Vector2.ZERO
var _home_decor1: Vector2 = Vector2(400, 1180)
var _home_decor2: Vector2 = Vector2(400, 1120)
var _punch_offset: Vector2 = Vector2.ZERO
var _punch_tween: Tween
var _blur_shader: Shader
var _board_root: Node2D
var _board_shadow: ColorRect
var _board_border: Node2D
var _board_tapes: Node2D
var _mat_tiles: Node2D
var _board_origin: Vector2 = Vector2(200, 400)
var _board_aabb_size: Vector2 = Vector2(400, 400)
var _cell_size: float = 64.0


func _ready() -> void:
	if ResourceLoader.exists("res://assets/shaders/soft_blur.gdshader"):
		_blur_shader = load("res://assets/shaders/soft_blur.gdshader")
	_build_far()
	_build_desk()
	_build_board()
	_build_near()


func _build_far() -> void:
	var bg := Sprite2D.new()
	bg.name = "MatchBg"
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.z_index = -40
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
		_apply_blur(bg, 0.85)
		_bg = bg
		_home_bg = Vector2.ZERO
		add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.name = "MatchBgFallback"
		fallback.size = Vector2(800, 1280)
		fallback.color = Color(0.72, 0.84, 0.92, 1)
		fallback.z_index = -40
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg = fallback
		add_child(fallback)

	var far_tex := [
		"res://assets/textures/nuages/haut_0.png",
		"res://assets/textures/nuages/haut_1.png",
		"res://assets/textures/nuages/moyen_0.png",
	]
	var mid_tex := [
		"res://assets/textures/nuages/moyen_0.png",
		"res://assets/textures/nuages/moyen_1.png",
		"res://assets/textures/nuages/bas_0.png",
		"res://assets/textures/nuages/bas_1.png",
	]
	for i in 3:
		var home := Vector2(60.0 + i * 260.0, 70.0 + (i % 2) * 40.0)
		var c := _make_sprite(far_tex, home, 1.05 + i * 0.08, -36)
		_apply_blur(c, 0.5)
		if c.texture:
			_clouds_far.append(c)
			_register_cloud(c, home, 22.0 + i * 4.0, DEPTH_CLOUD_FAR)
	for i in 3:
		var home2 := Vector2(120.0 + i * 240.0, 140.0 + (i % 3) * 35.0)
		var c2 := _make_sprite(mid_tex, home2, 1.2 + i * 0.1, -32)
		_apply_blur(c2, 0.22)
		if c2.texture:
			_clouds_mid.append(c2)
			_register_cloud(c2, home2, 30.0 + i * 5.0, DEPTH_CLOUD_MID)


func _build_desk() -> void:
	_desk = ColorRect.new()
	_desk.name = "DeskBand"
	_desk.color = DESK
	_desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desk.z_index = -25
	_desk.position = Vector2(0, 920)
	_desk.size = Vector2(800, 360)
	add_child(_desk)
	_desk_side_l = ColorRect.new()
	_desk_side_l.color = DESK.darkened(0.08)
	_desk_side_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desk_side_l.z_index = -25
	_desk_side_l.position = Vector2(0, 200)
	_desk_side_l.size = Vector2(36, 720)
	add_child(_desk_side_l)
	_desk_side_r = ColorRect.new()
	_desk_side_r.color = DESK.darkened(0.08)
	_desk_side_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desk_side_r.z_index = -25
	_desk_side_r.position = Vector2(764, 200)
	_desk_side_r.size = Vector2(36, 720)
	add_child(_desk_side_r)


func _build_board() -> void:
	_board_root = Node2D.new()
	_board_root.name = "BoardFrame"
	_board_root.z_index = -8
	add_child(_board_root)
	_board_shadow = ColorRect.new()
	_board_shadow.color = Color(0.05, 0.03, 0.02, 0.35)
	_board_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_shadow.z_index = -1
	_board_root.add_child(_board_shadow)
	_mat_tiles = Node2D.new()
	_mat_tiles.name = "MatTiles"
	_board_root.add_child(_mat_tiles)
	_board_border = Node2D.new()
	_board_border.name = "Border"
	_board_root.add_child(_board_border)
	_board_tapes = Node2D.new()
	_board_tapes.name = "Tapes"
	_board_root.add_child(_board_tapes)


func _build_near() -> void:
	_decor2 = _make_sprite([
		"res://assets/textures/decor2/decor2nd_0.png",
		"res://assets/textures/decor2/2emeplan.png",
	], _home_decor2, 1.6, -3)
	_decor1 = _make_sprite([
		"res://assets/textures/decor1/decor1er_0.png",
		"res://assets/textures/decor1/decor1er_1.png",
	], _home_decor1, 1.7, -2)


func _register_cloud(c: Sprite2D, home: Vector2, speed: float, depth: float) -> void:
	_cloud_base_x.append(home.x)
	_cloud_base_y.append(home.y)
	_cloud_speeds.append(speed)
	_cloud_depths.append(depth)
	c.set_meta("cloud_idx", _cloud_base_x.size() - 1)


func _apply_blur(node: CanvasItem, amount: float) -> void:
	if _blur_shader == null or bool(SaveService.options.get("reduce_motion", false)):
		return
	var mat := ShaderMaterial.new()
	mat.shader = _blur_shader
	mat.set_shader_parameter("blur_amount", amount)
	node.material = mat


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


## origin = top-left of cell (0, screen-top row); playable is grid.playable [x][y] with y=0 bottom.
func layout_board(origin: Vector2, cell_size: float, playable_mask: Array) -> void:
	_cell_size = cell_size
	_board_origin = origin
	if _board_root == null:
		return
	for c in _mat_tiles.get_children():
		c.queue_free()
	for c in _board_border.get_children():
		c.queue_free()
	for c in _board_tapes.get_children():
		c.queue_free()

	var n := playable_mask.size()
	if n <= 0:
		_board_shadow.visible = false
		return

	var min_sx := 999
	var max_sx := -1
	var min_sy := 999
	var max_sy := -1
	var any := false
	for x in n:
		var col: Array = playable_mask[x]
		for gy in col.size():
			if not bool(col[gy]):
				continue
			any = true
			# Model y=0 bottom -> screen row from top
			var sy := (n - 1) - gy
			min_sx = mini(min_sx, x)
			max_sx = maxi(max_sx, x)
			min_sy = mini(min_sy, sy)
			max_sy = maxi(max_sy, sy)
			var tile := ColorRect.new()
			tile.color = KRAFT.lightened(0.04 * float((x + gy) % 3))
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.position = origin + Vector2(float(x) * cell_size, float(sy) * cell_size)
			tile.size = Vector2(cell_size + 0.5, cell_size + 0.5)
			_mat_tiles.add_child(tile)
	if not any:
		_board_shadow.visible = false
		return

	var pad := 14.0
	var aabb_pos := origin + Vector2(float(min_sx) * cell_size, float(min_sy) * cell_size) - Vector2(pad, pad)
	var aabb_size := Vector2(
		float(max_sx - min_sx + 1) * cell_size + pad * 2.0,
		float(max_sy - min_sy + 1) * cell_size + pad * 2.0
	)
	_board_aabb_size = aabb_size
	_board_shadow.visible = true
	_board_shadow.position = aabb_pos + Vector2(8, 10)
	_board_shadow.size = aabb_size

	var thick := 10.0
	_add_border_rect(aabb_pos, Vector2(aabb_size.x, thick)) # top
	_add_border_rect(aabb_pos + Vector2(0, aabb_size.y - thick), Vector2(aabb_size.x, thick)) # bottom
	_add_border_rect(aabb_pos, Vector2(thick, aabb_size.y)) # left
	_add_border_rect(aabb_pos + Vector2(aabb_size.x - thick, 0), Vector2(thick, aabb_size.y)) # right

	_add_tape(aabb_pos + Vector2(8, -4), deg_to_rad(-12))
	_add_tape(aabb_pos + Vector2(aabb_size.x - 70, -2), deg_to_rad(10))
	_add_tape(aabb_pos + Vector2(4, aabb_size.y - 18), deg_to_rad(8))
	_add_tape(aabb_pos + Vector2(aabb_size.x - 74, aabb_size.y - 16), deg_to_rad(-9))

	# Keep near scraps under the board AABB.
	_home_decor2 = Vector2(aabb_pos.x + aabb_size.x * 0.25, aabb_pos.y + aabb_size.y + 70.0)
	_home_decor1 = Vector2(aabb_pos.x + aabb_size.x * 0.75, aabb_pos.y + aabb_size.y + 90.0)


func _add_border_rect(pos: Vector2, sz: Vector2) -> void:
	var r := ColorRect.new()
	r.color = CARDBOARD
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = pos
	r.size = sz
	_board_border.add_child(r)


func _add_tape(pos: Vector2, rot: float) -> void:
	var t := ColorRect.new()
	t.color = TAPE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = Vector2(64, 16)
	t.position = pos
	t.rotation = rot
	_board_tapes.add_child(t)


func scroll(delta: float, speed: float) -> void:
	_scroll += delta * speed
	var reduce := bool(SaveService.options.get("reduce_motion", false))
	var ambient_bg := Vector2.ZERO
	var sway1 := 0.0
	var sway2 := 0.0
	var cloud_mul := clampf(0.85 + speed * 0.5, 0.85, 1.35)
	if not reduce:
		ambient_bg = Vector2(sin(_scroll * 0.4) * 4.0, cos(_scroll * 0.3) * 3.0)
		sway1 = sin(_scroll * 0.7) * 10.0
		sway2 = cos(_scroll * 0.55) * 8.0
	else:
		cloud_mul = 0.0

	if _bg:
		_bg.position = _home_bg + ambient_bg + _punch_offset * DEPTH_BG
	if _desk:
		_desk.position = Vector2(_punch_offset.x * DEPTH_DESK, 920.0 + _punch_offset.y * DEPTH_DESK)
	if _desk_side_l:
		_desk_side_l.position = Vector2(_punch_offset.x * DEPTH_DESK, 200.0 + _punch_offset.y * DEPTH_DESK)
	if _desk_side_r:
		_desk_side_r.position = Vector2(764.0 + _punch_offset.x * DEPTH_DESK, 200.0 + _punch_offset.y * DEPTH_DESK)
	if _board_root:
		_board_root.position = _punch_offset * DEPTH_FRAME
	if _decor1 and _decor1.texture:
		_decor1.position = Vector2(_home_decor1.x + sway1, _home_decor1.y) + _punch_offset * DEPTH_NEAR
	if _decor2 and _decor2.texture:
		_decor2.position = Vector2(_home_decor2.x + sway2, _home_decor2.y) + _punch_offset * DEPTH_NEAR

	var all_clouds: Array = []
	all_clouds.append_array(_clouds_far)
	all_clouds.append_array(_clouds_mid)
	for c in all_clouds:
		if c == null or not is_instance_valid(c):
			continue
		var idx: int = int(c.get_meta("cloud_idx", -1))
		if idx < 0 or idx >= _cloud_base_x.size():
			continue
		var drift: float = float(_cloud_speeds[idx]) * cloud_mul
		_cloud_base_x[idx] = float(_cloud_base_x[idx]) + delta * drift
		var half_w := 120.0
		if c.texture:
			half_w = c.texture.get_size().x * absf(c.scale.x) * 0.55
		var left_limit := -half_w - 40.0
		var right_limit := VIEW_W + half_w + 40.0
		# Recycle only when fully off-screen so wrap is invisible.
		if _cloud_base_x[idx] > right_limit:
			_cloud_base_x[idx] = left_limit
			_cloud_base_y[idx] = clampf(
				float(_cloud_base_y[idx]) + randf_range(-18.0, 18.0),
				40.0,
				220.0
			)
		var depth: float = float(_cloud_depths[idx])
		var x := float(_cloud_base_x[idx]) + _punch_offset.x * depth
		var y := float(_cloud_base_y[idx]) + _punch_offset.y * depth
		c.position = Vector2(x, y)
		# Soft fade at viewport edges (covers blur halo / oversized sprites).
		var edge_a := 1.0
		if x < CLOUD_EDGE_FADE:
			edge_a = clampf(x / CLOUD_EDGE_FADE, 0.0, 1.0)
		elif x > VIEW_W - CLOUD_EDGE_FADE:
			edge_a = clampf((VIEW_W - x) / CLOUD_EDGE_FADE, 0.0, 1.0)
		c.modulate.a = edge_a


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
