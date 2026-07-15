class_name JuiceFx
extends Node2D

## Candy-like match feedback: particles, float text, shake, glow/flash shaders.

var shake_target: Node2D
var flash_overlay: ColorRect
var combo_label: Label
var _trail: CPUParticles2D
var _spark: Texture2D
var _glow_shader: Shader
var _flash_mat: ShaderMaterial
var _shake_tween: Tween
var _base_shake_pos: Vector2 = Vector2.ZERO
var level_locked: bool = false


func setup(shake_node: Node2D) -> void:
	shake_target = shake_node
	_spark = _make_spark_texture()
	if ResourceLoader.exists("res://assets/shaders/leaf_glow.gdshader"):
		_glow_shader = load("res://assets/shaders/leaf_glow.gdshader")
	_setup_flash()
	_setup_combo_label()
	_setup_trail()


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
	UiTheme.style_label(combo_label, 56)
	combo_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_label.offset_left = -220
	combo_label.offset_right = 220
	combo_label.offset_top = -40
	combo_label.offset_bottom = 40
	var parent_ctrl := get_parent()
	if parent_ctrl is Control:
		(parent_ctrl as Control).add_child(combo_label)
	else:
		add_child(combo_label)


func _setup_trail() -> void:
	_trail = CPUParticles2D.new()
	_trail.emitting = false
	_trail.one_shot = false
	_trail.amount = 18
	_trail.lifetime = 0.35
	_trail.explosiveness = 0.0
	_trail.local_coords = false
	_trail.direction = Vector2(0, -1)
	_trail.spread = 180.0
	_trail.initial_velocity_min = 10.0
	_trail.initial_velocity_max = 40.0
	_trail.gravity = Vector2.ZERO
	_trail.scale_amount_min = 0.3
	_trail.scale_amount_max = 0.7
	_trail.texture = _spark
	add_child(_trail)


func burst_at(screen_pos: Vector2, leaf_type: int, amount: int = 18) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.position = screen_pos
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 220.0
	p.gravity = Vector2(0, 280)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.1
	p.texture = _spark
	var c := LeafPalette.color_for(leaf_type)
	p.color = c
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)


func confetti(center: Vector2, count: int = 60) -> void:
	for i in 8:
		burst_at(center + Vector2(randf_range(-120, 120), randf_range(-80, 80)), i % 8, count / 8)


func float_text(screen_pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.z_index = 50
	UiTheme.style_label(lbl, 32)
	lbl.label_settings = UiTheme.label_settings(32, color)
	lbl.position = screen_pos + Vector2(-40, -10)
	lbl.modulate.a = 1.0
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 60.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.55)
	tw.finished.connect(func():
		if is_instance_valid(lbl):
			lbl.queue_free()
	)


func combo_banner(chain: int) -> void:
	if chain < 2 or combo_label == null:
		return
	var word := "Nice!"
	if chain >= 6:
		word = "Legendary!"
	elif chain >= 4:
		word = "Awesome!"
	elif chain >= 3:
		word = "Great!"
	combo_label.text = word
	combo_label.visible = true
	combo_label.modulate.a = 0.0
	combo_label.scale = Vector2(0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(combo_label, "modulate:a", 1.0, 0.1)
	tw.parallel().tween_property(combo_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(combo_label, "modulate:a", 0.0, 0.2)
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


func punch_scale(spr: Node2D, base_scale: Vector2, peak: float = 1.14, duration: float = 0.16) -> void:
	if spr == null:
		return
	var tw := create_tween()
	tw.tween_property(spr, "scale", base_scale * peak, duration * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", base_scale, duration * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func wobble(spr: Node2D) -> void:
	if spr == null:
		return
	var base_rot := spr.rotation
	var tw := create_tween()
	tw.tween_property(spr, "rotation", base_rot + deg_to_rad(14), 0.05)
	tw.tween_property(spr, "rotation", base_rot - deg_to_rad(14), 0.08)
	tw.tween_property(spr, "rotation", base_rot, 0.07)


func start_trail(leaf_type: int) -> void:
	if _trail == null:
		return
	_trail.color = LeafPalette.color_for(leaf_type)
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
