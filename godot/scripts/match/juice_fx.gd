class_name JuiceFx
extends Node2D

## Candy-like match feedback v2: arcs, squash, shockwaves, layered particles.

var shake_target: Node2D
## Optional MatchDecor (or any node with parallax_punch).
var parallax_host: Node
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
var _burst_pool: Array = []
var _line_pool: Array = []
var _telegraph_nodes: Array = []
var _shadow_tex: Texture2D


func _acquire_burst() -> CPUParticles2D:
	while not _burst_pool.is_empty():
		var p = _burst_pool.pop_back()
		if is_instance_valid(p):
			return p
	var fresh := CPUParticles2D.new()
	add_child(fresh)
	return fresh


func _release_burst(p: CPUParticles2D) -> void:
	if not is_instance_valid(p):
		return
	p.emitting = false
	if _burst_pool.size() < 24:
		_burst_pool.append(p)
	else:
		p.queue_free()


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
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	if bool(SaveService.options.get("reduce_motion", false)):
		return
	var p := _acquire_burst()
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
	if p.get_parent() != self:
		add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.35).timeout.connect(func():
		_release_burst(p)
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
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var col := Color(0.92, 0.72, 0.28)
	if chain >= 6:
		word = "Legendary!"
		col = Color(0.78, 0.38, 0.55)
	elif chain >= 4:
		word = "Awesome!"
		col = Color(0.9, 0.55, 0.22)
	elif chain >= 3:
		word = "Great!"
		col = Color(0.35, 0.62, 0.42)
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


func special_created(text: String, color: Color = Color.WHITE) -> void:
	if text == "":
		return
	if SaveService.options.get("reduce_motion", false):
		float_text(get_viewport_rect().size * 0.5 + Vector2(-60, -80), text, color)
		return
	float_text(get_viewport_rect().size * 0.5 + Vector2(-80, -120), text, color)
	camera_punch(7.0, 0.1)
	screen_flash(0.22, 0.08)


func camera_punch(strength: float = 6.0, duration: float = 0.12, chain: int = 1) -> void:
	var scaled := strength * juice_scale(chain)
	if parallax_host and parallax_host.has_method("parallax_punch") and not _reduce_motion():
		parallax_host.parallax_punch(scaled * 0.85, maxf(0.18, duration + 0.08))
	if shake_target == null:
		return
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		shake_target.position = _base_shake_pos
	_base_shake_pos = shake_target.position
	_shake_tween = create_tween()
	var ox := randf_range(-scaled, scaled)
	var oy := randf_range(-scaled, scaled)
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
	var squash := Vector2(base_scale.x * 1.22, base_scale.y * 0.68)
	var tw := create_tween()
	tw.tween_property(spr, "scale", squash, duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", base_scale * 1.08, duration * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", base_scale, duration * 0.3)
	if not _reduce_motion():
		land_shadow_flash(spr, duration + 0.08)


## Temporary contact shadow under a piece on land (not a permanent child).
func land_shadow_flash(spr: Node2D, duration: float = 0.22) -> void:
	if spr == null or _reduce_motion():
		return
	if _shadow_tex == null:
		_shadow_tex = _make_shadow_texture()
	var shadow := Sprite2D.new()
	shadow.texture = _shadow_tex
	shadow.centered = true
	shadow.z_index = -1
	shadow.modulate = Color(0.08, 0.05, 0.02, 0.0)
	shadow.scale = Vector2(1.4, 0.45)
	shadow.position = Vector2(0, 18)
	spr.add_child(shadow)
	var tw := create_tween()
	tw.tween_property(shadow, "modulate:a", 0.55, duration * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(shadow, "scale", Vector2(1.85, 0.38), duration * 0.25)
	tw.tween_property(shadow, "modulate:a", 0.0, duration * 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(shadow, "scale", Vector2(1.1, 0.5), duration * 0.75)
	tw.finished.connect(func():
		if is_instance_valid(shadow):
			shadow.queue_free()
	)


## Paper flutter fall: owns position + rotation for the wave (includes overshoot land).
## Returns the tween so callers can await finish; no-ops to a completed tween if reduce_motion.
func fall_flutter(spr: Node2D, from_pos: Vector2, land_pos: Vector2, dur: float) -> Tween:
	var tw := create_tween().set_parallel(true)
	if spr == null:
		return tw
	if _reduce_motion() or dur <= 0.01:
		spr.position = land_pos
		spr.rotation = 0.0
		return tw
	spr.position = from_pos
	spr.rotation = 0.0
	var amp_rot := deg_to_rad(randf_range(12.0, 22.0)) * (1.0 if randf() > 0.5 else -1.0)
	var mid_x := lerpf(from_pos.x, land_pos.x, 0.45) + randf_range(8.0, 14.0) * (1.0 if randf() > 0.5 else -1.0)
	var mid := Vector2(mid_x, lerpf(from_pos.y, land_pos.y, 0.55))
	var overshoot := land_pos + Vector2(0, 14.0)
	var drop := dur * 0.82
	var settle := dur * 0.18
	tw.tween_property(spr, "position", mid, drop * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "position", overshoot, drop * 0.45).set_delay(drop * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(spr, "position", land_pos, settle).set_delay(drop).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "rotation", amp_rot, dur * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "rotation", -amp_rot * 0.65, dur * 0.35).set_delay(dur * 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(spr, "rotation", 0.0, dur * 0.25).set_delay(dur * 0.75).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func():
		if is_instance_valid(spr):
			spr.rotation = 0.0
			spr.position = land_pos
	)
	return tw


## Rotation-only flutter for spawn (position owned by caller).
func paper_spin_flutter(spr: Node2D, dur: float) -> void:
	if spr == null or _reduce_motion() or dur <= 0.01:
		return
	var amp_rot := deg_to_rad(randf_range(12.0, 20.0)) * (1.0 if randf() > 0.5 else -1.0)
	var tw := create_tween()
	tw.tween_property(spr, "rotation", amp_rot, dur * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "rotation", -amp_rot * 0.55, dur * 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(spr, "rotation", 0.0, dur * 0.25).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func():
		if is_instance_valid(spr):
			spr.rotation = 0.0
	)


## Fake card flip via scale.x collapse.
func paper_flip(spr: Node2D, base_scale: Vector2, dur: float = 0.22) -> void:
	if spr == null or _reduce_motion() or dur <= 0.01:
		return
	var base_mod := spr.modulate
	var edge := Color(base_mod.r * 0.55, base_mod.g * 0.55, base_mod.b * 0.6, base_mod.a)
	var flat := Vector2(base_scale.x * 0.05, base_scale.y * 1.08)
	var tw := create_tween()
	tw.tween_property(spr, "scale", flat, dur * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(spr, "modulate", edge, dur * 0.4)
	tw.tween_property(spr, "scale", base_scale * Vector2(1.06, 0.96), dur * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(spr, "modulate", base_mod, dur * 0.35)
	tw.tween_property(spr, "scale", base_scale, dur * 0.25)
	tw.finished.connect(func():
		if is_instance_valid(spr):
			spr.scale = base_scale
			spr.modulate = base_mod
	)


func wobble(spr: Node2D, home_pos: Vector2 = Vector2.INF) -> void:
	## Rotation-only shake; snaps back to home_pos so invalid swaps never drift.
	if spr == null:
		return
	if spr.has_meta("wobble_tween"):
		var prev = spr.get_meta("wobble_tween")
		if prev is Tween and is_instance_valid(prev):
			(prev as Tween).kill()
	var home := home_pos
	if home == Vector2.INF:
		home = spr.position
	else:
		spr.position = home
	spr.rotation = 0.0
	var tw := create_tween()
	spr.set_meta("wobble_tween", tw)
	tw.tween_property(spr, "rotation", deg_to_rad(14), 0.05)
	tw.tween_property(spr, "rotation", deg_to_rad(-14), 0.08)
	tw.tween_property(spr, "rotation", 0.0, 0.07)
	tw.finished.connect(func():
		if is_instance_valid(spr):
			spr.position = home
			spr.rotation = 0.0
			if spr.has_meta("wobble_tween"):
				spr.remove_meta("wobble_tween")
	)


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
	outward = outward.normalized() * randf_range(55.0, 125.0)
	var mid := from + outward * 0.45 + Vector2(0, -50)
	var end := from + outward
	var do_flip := not _reduce_motion() and randf() < 0.5
	var start_scale := spr.scale
	tw.tween_property(spr, "position", mid, dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "position", end, dur * 0.55).set_delay(dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(spr, "rotation", spr.rotation + deg_to_rad(randf_range(-280, 280)), dur)
	if do_flip:
		tw.tween_property(spr, "scale", Vector2(start_scale.x * 0.08, start_scale.y * 1.1), dur * 0.35)
		tw.tween_property(spr, "scale", start_scale * 0.05, dur * 0.65).set_delay(dur * 0.35)
	else:
		tw.tween_property(spr, "scale", start_scale * 0.05, dur)
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


func _reduce_motion() -> bool:
	return bool(SaveService.options.get("reduce_motion", false))


func _acquire_line() -> Line2D:
	while not _line_pool.is_empty():
		var ln = _line_pool.pop_back()
		if is_instance_valid(ln):
			ln.clear_points()
			ln.visible = true
			return ln
	var fresh := Line2D.new()
	fresh.z_index = 28
	fresh.begin_cap_mode = Line2D.LINE_CAP_ROUND
	fresh.end_cap_mode = Line2D.LINE_CAP_ROUND
	fresh.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(fresh)
	return fresh


func _release_line(ln: Line2D) -> void:
	if not is_instance_valid(ln):
		return
	ln.clear_points()
	ln.visible = false
	_telegraph_nodes.erase(ln)
	if _line_pool.size() < 32:
		_line_pool.append(ln)
	else:
		ln.queue_free()


func clear_telegraphs() -> void:
	for n in _telegraph_nodes.duplicate():
		if n is Line2D:
			_release_line(n)
		elif is_instance_valid(n):
			n.queue_free()
	_telegraph_nodes.clear()


## Thin yarn / glitter threads from centroid to each match cell (screen positions).
func telegraph_match(screen_points: Array, color: Color, dur: float, glow_sprites: Array = [], leaf_type: int = 0) -> void:
	if _reduce_motion() or screen_points.is_empty():
		return
	var mid := Vector2.ZERO
	for s in screen_points:
		mid += s as Vector2
	mid /= float(screen_points.size())
	for s in screen_points:
		_spawn_thread(mid, s as Vector2, color, 1.8, dur, 0.55)
	for spr in glow_sprites:
		if spr is CanvasItem and is_instance_valid(spr):
			apply_glow(spr, leaf_type, 0.55)
			var held: CanvasItem = spr
			var tw := create_tween()
			tw.tween_interval(dur)
			tw.tween_callback(func():
				clear_glow(held)
			)


## Masking-tape sweep along a row (horizontal) or column.
func telegraph_stripe(origin: Vector2, horizontal: bool, half_extent: float, color: Color, dur: float) -> void:
	if _reduce_motion():
		return
	var tape := Line2D.new()
	tape.z_index = 29
	tape.width = 10.0
	tape.default_color = Color(color.r, color.g, color.b, 0.75).lightened(0.15)
	tape.begin_cap_mode = Line2D.LINE_CAP_BOX
	tape.end_cap_mode = Line2D.LINE_CAP_BOX
	add_child(tape)
	_telegraph_nodes.append(tape)
	if horizontal:
		tape.add_point(origin)
		tape.add_point(origin)
		var tw := create_tween()
		tw.tween_method(func(t: float):
			if not is_instance_valid(tape):
				return
			tape.clear_points()
			tape.add_point(origin + Vector2(-half_extent * t, 0))
			tape.add_point(origin + Vector2(half_extent * t, 0))
		, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(tape, "modulate:a", 0.0, dur).set_delay(dur * 0.45)
		tw.finished.connect(func():
			if is_instance_valid(tape):
				_telegraph_nodes.erase(tape)
				tape.queue_free()
		)
	else:
		tape.add_point(origin)
		tape.add_point(origin)
		var tw2 := create_tween()
		tw2.tween_method(func(t: float):
			if not is_instance_valid(tape):
				return
			tape.clear_points()
			tape.add_point(origin + Vector2(0, -half_extent * t))
			tape.add_point(origin + Vector2(0, half_extent * t))
		, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.parallel().tween_property(tape, "modulate:a", 0.0, dur).set_delay(dur * 0.45)
		tw2.finished.connect(func():
			if is_instance_valid(tape):
				_telegraph_nodes.erase(tape)
				tape.queue_free()
		)


## Foil rays from bomb origin to each same-color target (staggered, capped).
func telegraph_bomb(origin: Vector2, targets: Array, color: Color, dur: float) -> void:
	if _reduce_motion() or targets.is_empty():
		return
	var foil := Color(color.r * 0.7 + 0.35, color.g * 0.7 + 0.35, color.b * 0.55 + 0.45, 0.9)
	var max_rays := mini(targets.size(), 10)
	for i in max_rays:
		var tgt: Vector2 = targets[i] if targets[i] is Vector2 else Vector2(targets[i])
		var delay := dur * 0.55 * float(i) / float(maxi(1, max_rays - 1))
		get_tree().create_timer(delay).timeout.connect(func():
			_spawn_thread(origin, tgt, foil, 3.2, dur * 0.65, 0.85)
		)


## Cardboard ring grow over wrapped 3x3 area.
func telegraph_wrapped(center: Vector2, color: Color, dur: float, radius: float = 70.0) -> void:
	if _reduce_motion():
		return
	shockwave(center, Color(color.r, color.g, color.b, 0.85), radius)
	var ring2 := Sprite2D.new()
	ring2.texture = _ring
	ring2.centered = true
	ring2.position = center
	ring2.modulate = color.darkened(0.1)
	ring2.scale = Vector2(0.2, 0.2)
	ring2.z_index = 29
	add_child(ring2)
	_telegraph_nodes.append(ring2)
	var target := radius / 28.0
	var tw := create_tween()
	tw.tween_property(ring2, "scale", Vector2(target, target), dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring2, "modulate:a", 0.0, dur)
	tw.finished.connect(func():
		if is_instance_valid(ring2):
			_telegraph_nodes.erase(ring2)
			ring2.queue_free()
	)


## Paper-plane trails to a few priority targets.
func telegraph_fish(origin: Vector2, targets: Array, color: Color, dur: float) -> void:
	if _reduce_motion() or targets.is_empty():
		return
	var n := mini(targets.size(), 3)
	for i in n:
		var tgt: Vector2 = targets[i] if targets[i] is Vector2 else Vector2(targets[i])
		_spawn_thread(origin, tgt, color.lightened(0.2), 2.4, dur, 0.7)
		# Small dart tip
		var tip := Sprite2D.new()
		tip.texture = _star
		tip.centered = true
		tip.position = origin
		tip.modulate = color
		tip.scale = Vector2(0.9, 0.9)
		tip.z_index = 30
		add_child(tip)
		_telegraph_nodes.append(tip)
		var tw := create_tween()
		tw.tween_property(tip, "position", tgt, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(tip, "scale", Vector2(0.2, 0.2), dur)
		tw.parallel().tween_property(tip, "modulate:a", 0.0, dur * 0.9)
		tw.finished.connect(func():
			if is_instance_valid(tip):
				_telegraph_nodes.erase(tip)
				tip.queue_free()
		)


func _spawn_thread(from: Vector2, to: Vector2, color: Color, width: float, dur: float, peak_a: float) -> void:
	var ln := _acquire_line()
	ln.width = width
	ln.default_color = Color(color.r, color.g, color.b, peak_a)
	ln.clear_points()
	ln.add_point(from)
	ln.add_point(from)
	_telegraph_nodes.append(ln)
	var tw := create_tween()
	tw.tween_method(func(t: float):
		if not is_instance_valid(ln):
			return
		ln.clear_points()
		ln.add_point(from)
		ln.add_point(from.lerp(to, t))
	, 0.0, 1.0, dur * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ln, "modulate:a", 0.0, dur * 0.45)
	tw.finished.connect(func():
		_release_line(ln)
	)


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


func _make_shadow_texture() -> Texture2D:
	var img := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	var cx := 15.5
	var cy := 7.5
	for y in 16:
		for x in 32:
			var nx := (x - cx) / 15.0
			var ny := (y - cy) / 7.0
			var d := sqrt(nx * nx + ny * ny)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * 0.9
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
