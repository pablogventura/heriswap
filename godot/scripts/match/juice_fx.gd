class_name JuiceFx
extends Node2D

## Candy-like match feedback v2: arcs, squash, shockwaves, layered particles.

var shake_target: Node2D
var flash_overlay: ColorRect
var combo_label: Label
var _trail: CPUParticles2D
var _spark: Texture2D
var _star: Texture2D
var _ring: Texture2D
var _glow_shader: Shader
var _pop_shader: Shader
var _flash_mat: ShaderMaterial
var _shake_tween: Tween
var _zoom_tween: Tween
var _base_shake_pos: Vector2 = Vector2.ZERO
var _base_zoom_scale: Vector2 = Vector2.ONE
var level_locked: bool = false


func setup(shake_node: Node2D) -> void:
	shake_target = shake_node
	if shake_target:
		_base_zoom_scale = shake_target.scale
	_spark = _make_spark_texture()
	_star = _make_star_texture()
	_ring = _make_ring_texture()
	if ResourceLoader.exists("res://assets/shaders/leaf_glow.gdshader"):
		_glow_shader = load("res://assets/shaders/leaf_glow.gdshader")
	if ResourceLoader.exists("res://assets/shaders/leaf_pop.gdshader"):
		_pop_shader = load("res://assets/shaders/leaf_pop.gdshader")
	_setup_flash()
	_setup_combo_label()
	_setup_trail()


func juice_scale(chain: int) -> float:
	return clampf(1.0 + 0.12 * float(chain - 1), 1.0, 1.6)


func _setup_flash() -> void:
	flash_overlay = ColorRect.new()
	flash_overlay.name = "ScreenFlash"
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.color = Color(1, 1, 1, 0)
	if ResourceLoader.exists("res://assets/shaders/screen_flash.gdshader"):
		_flash_mat = ShaderMaterial.new()
		_flash_mat.shader = load("res://assets/shaders/screen_flash.gdshader")
		_flash_mat.set_shader_parameter("intensity", 0.0)
		flash_overlay.material = _flash_mat
	var parent_ctrl := get_parent()
	if parent_ctrl is Control:
		(parent_ctrl as Control).add_child(flash_overlay)
		(parent_ctrl as Control).move_child(flash_overlay, (parent_ctrl as Control).get_child_count() - 1)
	else:
		add_child(flash_overlay)


func _setup_combo_label() -> void:
	combo_label = Label.new()
	combo_label.visible = false
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.z_index = 40
	UiTheme.style_label(combo_label, 60)
	combo_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_label.offset_left = -240
	combo_label.offset_right = 240
	combo_label.offset_top = -50
	combo_label.offset_bottom = 50
	var parent_ctrl := get_parent()
	if parent_ctrl is Control:
		(parent_ctrl as Control).add_child(combo_label)
	else:
		add_child(combo_label)


func _setup_trail() -> void:
	_trail = CPUParticles2D.new()
	_trail.emitting = false
	_trail.one_shot = false
	_trail.amount = 28
	_trail.lifetime = 0.4
	_trail.explosiveness = 0.0
	_trail.local_coords = false
	_trail.direction = Vector2(0, -1)
	_trail.spread = 180.0
	_trail.initial_velocity_min = 12.0
	_trail.initial_velocity_max = 55.0
	_trail.gravity = Vector2.ZERO
	_trail.scale_amount_min = 0.35
	_trail.scale_amount_max = 0.85
	_trail.texture = _spark
	add_child(_trail)


func burst_at(screen_pos: Vector2, leaf_type: int, amount: int = 18) -> void:
	_spawn_burst(screen_pos, leaf_type, amount, _spark, 0.45, 80.0, 220.0, 280.0)
	_spawn_burst(screen_pos, leaf_type, maxi(6, amount / 2), _star, 0.65, 40.0, 120.0, 40.0)


func _spawn_burst(pos: Vector2, leaf_type: int, amount: int, tex: Texture2D, life: float, vmin: float, vmax: float, grav: float) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.position = pos
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector2(0, grav)
	p.scale_amount_min = 0.35
	p.scale_amount_max = 1.15
	p.texture = tex
	p.color = LeafPalette.color_for(leaf_type)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.35).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)


func dust_at(screen_pos: Vector2, leaf_type: int = 0) -> void:
	_spawn_burst(screen_pos, leaf_type, 8, _spark, 0.28, 30.0, 90.0, 420.0)


func confetti(center: Vector2, count: int = 60) -> void:
	for i in 8:
		burst_at(center + Vector2(randf_range(-120, 120), randf_range(-80, 80)), i % 8, count / 8)


func float_text(screen_pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.z_index = 50
	lbl.label_settings = UiTheme.label_settings(34, color)
	lbl.position = screen_pos + Vector2(-40, -10)
	lbl.scale = Vector2(0.7, 0.7)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "position:y", lbl.position.y - 70.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.25)
	tw.finished.connect(func():
		if is_instance_valid(lbl):
			lbl.queue_free()
	)


func combo_banner(chain: int) -> void:
	if chain < 2 or combo_label == null:
		return
	var word := "Nice!"
	var col := Color(1.0, 0.95, 0.55)
	if chain >= 6:
		word = "Legendary!"
		col = Color(1.0, 0.45, 0.85)
	elif chain >= 4:
		word = "Awesome!"
		col = Color(1.0, 0.7, 0.25)
	elif chain >= 3:
		word = "Great!"
		col = Color(0.45, 1.0, 0.55)
	combo_label.text = word
	combo_label.label_settings = UiTheme.label_settings(64, col)
	combo_label.visible = true
	combo_label.modulate.a = 0.0
	combo_label.scale = Vector2(0.35, 0.35)
	var peak := 1.0 + 0.08 * float(mini(chain, 6))
	var tw := create_tween()
	tw.tween_property(combo_label, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(combo_label, "scale", Vector2(peak, peak), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(combo_label, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.22)
	tw.tween_property(combo_label, "modulate:a", 0.0, 0.18)
	tw.finished.connect(func():
		combo_label.visible = false
	)


func camera_punch(strength: float = 6.0, duration: float = 0.12) -> void:
	if shake_target == null:
		return
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		shake_target.position = _base_shake_pos
	_base_shake_pos = shake_target.position
	_shake_tween = create_tween()
	var ox := randf_range(-strength, strength)
	var oy := randf_range(-strength, strength)
	_shake_tween.tween_property(shake_target, "position", _base_shake_pos + Vector2(ox, oy), duration * 0.35)
	_shake_tween.tween_property(shake_target, "position", _base_shake_pos + Vector2(-ox * 0.5, -oy * 0.5), duration * 0.35)
	_shake_tween.tween_property(shake_target, "position", _base_shake_pos, duration * 0.3)


func zoom_punch(amount: float = 0.04, duration: float = 0.16) -> void:
	if shake_target == null:
		return
	if _zoom_tween and _zoom_tween.is_valid():
		_zoom_tween.kill()
		shake_target.scale = _base_zoom_scale
	_base_zoom_scale = shake_target.scale
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(shake_target, "scale", _base_zoom_scale * (1.0 + amount), duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(shake_target, "scale", _base_zoom_scale, duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func screen_flash(alpha: float = 0.35, duration: float = 0.1) -> void:
	if flash_overlay == null:
		return
	if _flash_mat:
		_flash_mat.set_shader_parameter("intensity", 0.0)
		var tw := create_tween()
		tw.tween_method(func(v: float): _flash_mat.set_shader_parameter("intensity", v), 0.0, alpha, duration * 0.35)
		tw.tween_method(func(v: float): _flash_mat.set_shader_parameter("intensity", v), alpha, 0.0, duration * 0.65)
	else:
		flash_overlay.color.a = 0.0
		var tw2 := create_tween()
		tw2.tween_property(flash_overlay, "color:a", alpha, duration * 0.35)
		tw2.tween_property(flash_overlay, "color:a", 0.0, duration * 0.65)


func shockwave(pos: Vector2, color: Color, radius: float = 90.0) -> void:
	var ring := Sprite2D.new()
	ring.texture = _ring
	ring.centered = true
	ring.position = pos
	ring.modulate = color
	ring.scale = Vector2(0.15, 0.15)
	ring.z_index = 30
	add_child(ring)
	var target := radius / 32.0
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector2(target, target), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.28)
	tw.finished.connect(func():
		if is_instance_valid(ring):
			ring.queue_free()
	)


func apply_glow(spr: CanvasItem, leaf_type: int, amount: float = 1.0) -> void:
	if level_locked or spr == null or _glow_shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _glow_shader
	mat.set_shader_parameter("glow", amount)
	mat.set_shader_parameter("glow_color", LeafPalette.color_for(leaf_type))
	spr.material = mat


func clear_glow(spr: CanvasItem) -> void:
	if spr == null or level_locked:
		return
	spr.material = null


func apply_pop_flash(spr: CanvasItem, leaf_type: int, duration: float = 0.12) -> void:
	if level_locked or spr == null or _pop_shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _pop_shader
	mat.set_shader_parameter("pop", 0.0)
	mat.set_shader_parameter("pop_color", LeafPalette.color_for(leaf_type))
	spr.material = mat
	var tw := create_tween()
	tw.tween_method(func(v: float):
		if is_instance_valid(spr) and spr.material == mat:
			mat.set_shader_parameter("pop", v)
	, 0.0, 1.2, duration * 0.4)
	tw.tween_method(func(v: float):
		if is_instance_valid(spr) and spr.material == mat:
			mat.set_shader_parameter("pop", v)
	, 1.2, 0.0, duration * 0.6)
	tw.finished.connect(func():
		if is_instance_valid(spr) and spr.material == mat and not level_locked:
			spr.material = null
	)


func punch_scale(spr: Node2D, base_scale: Vector2, peak: float = 1.14, duration: float = 0.16) -> void:
	if spr == null:
		return
	var tw := create_tween()
	tw.tween_property(spr, "scale", base_scale * peak, duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", base_scale, duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func land_squash(spr: Node2D, base_scale: Vector2, duration: float = 0.14) -> void:
	if spr == null:
		return
	var squash := Vector2(base_scale.x * 1.18, base_scale.y * 0.72)
	var tw := create_tween()
	tw.tween_property(spr, "scale", squash, duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", base_scale * 1.06, duration * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", base_scale, duration * 0.3)


func wobble(spr: Node2D) -> void:
	if spr == null:
		return
	var base_rot := spr.rotation
	var base_pos := spr.position
	var tw := create_tween()
	tw.tween_property(spr, "rotation", base_rot + deg_to_rad(16), 0.05)
	tw.parallel().tween_property(spr, "position", base_pos + Vector2(4, 0), 0.05)
	tw.tween_property(spr, "rotation", base_rot - deg_to_rad(16), 0.08)
	tw.parallel().tween_property(spr, "position", base_pos + Vector2(-4, 0), 0.08)
	tw.tween_property(spr, "rotation", base_rot, 0.07)
	tw.parallel().tween_property(spr, "position", base_pos, 0.07)


## Anticipation before swap; returns a Tween that finishes when ready to lerp.
func anticipate_swap(sa: Node2D, sb: Node2D, base_a: Vector2, base_b: Vector2, dur: float = 0.08) -> Tween:
	var tw := create_tween().set_parallel(true)
	if sa and sb:
		var dir_a := (sa.position - sb.position)
		if dir_a.length() > 0.01:
			dir_a = dir_a.normalized()
		else:
			dir_a = Vector2.LEFT
		var dir_b := -dir_a
		tw.tween_property(sa, "scale", base_a * 0.88, dur)
		tw.tween_property(sa, "position", sa.position + dir_a * 5.0, dur)
		tw.tween_property(sb, "scale", base_b * 0.88, dur)
		tw.tween_property(sb, "position", sb.position + dir_b * 5.0, dur)
	return tw


## Arc explode used during delete. Returns tween for chaining.
func explode_leaf(spr: Node2D, center: Vector2, dur: float) -> Tween:
	var tw := create_tween().set_parallel(true)
	if spr == null:
		return tw
	var from := spr.position
	var outward := (from - center)
	if outward.length() < 2.0:
		outward = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	outward = outward.normalized() * randf_range(50.0, 110.0)
	var mid := from + outward * 0.45 + Vector2(0, -35)
	var end := from + outward
	tw.tween_property(spr, "position", mid, dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "position", end, dur * 0.55).set_delay(dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(spr, "rotation", spr.rotation + deg_to_rad(randf_range(-220, 220)), dur)
	tw.tween_property(spr, "scale", spr.scale * 0.05, dur)
	tw.tween_property(spr, "modulate:a", 0.0, dur * 0.85)
	return tw


func pulse_progress(bar: ProgressBar) -> void:
	if bar == null:
		return
	var tw := create_tween()
	tw.tween_property(bar, "modulate", Color(1.4, 1.35, 1.1), 0.08)
	tw.tween_property(bar, "modulate", Color.WHITE, 0.18)


func hint_pulse(spr: CanvasItem, leaf_type: int) -> void:
	if spr == null:
		return
	apply_glow(spr, leaf_type, 0.6)
	var tw := create_tween()
	tw.tween_method(func(v: float):
		if is_instance_valid(spr) and spr.material is ShaderMaterial:
			(spr.material as ShaderMaterial).set_shader_parameter("glow", v)
	, 0.6, 1.5, 0.15)
	tw.tween_method(func(v: float):
		if is_instance_valid(spr) and spr.material is ShaderMaterial:
			(spr.material as ShaderMaterial).set_shader_parameter("glow", v)
	, 1.5, 0.6, 0.15)
	tw.tween_method(func(v: float):
		if is_instance_valid(spr) and spr.material is ShaderMaterial:
			(spr.material as ShaderMaterial).set_shader_parameter("glow", v)
	, 0.6, 1.4, 0.15)
	tw.tween_callback(func():
		clear_glow(spr)
	)


func start_trail(leaf_type: int) -> void:
	if _trail == null:
		return
	_trail.color = LeafPalette.color_for(leaf_type)
	_trail.amount = 28
	_trail.emitting = true


func update_trail(pos: Vector2) -> void:
	if _trail and _trail.emitting:
		_trail.global_position = pos


func stop_trail() -> void:
	if _trail:
		_trail.emitting = false


func _make_spark_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var cx := 7.5
	var cy := 7.5
	for y in 16:
		for x in 16:
			var d := Vector2(x - cx, y - cy).length()
			var a := clampf(1.0 - d / 7.0, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _make_star_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c := Vector2(7.5, 7.5)
	for y in 16:
		for x in 16:
			var p := Vector2(x, y) - c
			var d := absf(p.x) + absf(p.y)
			var arm := mini(absf(p.x), absf(p.y))
			var a := 0.0
			if d < 7.5:
				a = clampf(1.0 - d / 7.5, 0.0, 1.0)
				if arm < 1.6:
					a = maxf(a, 0.9)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)


func _make_ring_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var c := Vector2(31.5, 31.5)
	for y in 64:
		for x in 64:
			var d := Vector2(x, y).distance_to(c)
			var a := 0.0
			if d > 22.0 and d < 30.0:
				a = 1.0 - absf(d - 26.0) / 4.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
