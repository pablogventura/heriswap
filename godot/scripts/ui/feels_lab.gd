extends Control

## Juice feels playground for tuning FX (including paper clear telegraphs).

var _juice: JuiceFx
var _decor: MatchDecor
var _demo: Sprite2D
var _center := Vector2(400, 640)
var _ring_targets: Array = []


func _ready() -> void:
	UiTheme.apply_layered_menu_bg(self)
	_decor = MatchDecor.new()
	add_child(_decor)
	move_child(_decor, 0)
	_juice = JuiceFx.new()
	add_child(_juice)
	var layer := Node2D.new()
	add_child(layer)
	_juice.setup(layer)
	_juice.parallax_host = _decor
	_demo = Sprite2D.new()
	_demo.centered = true
	_demo.position = _center
	if ResourceLoader.exists("res://assets/textures/feuilles/feuille1.png"):
		_demo.texture = load("res://assets/textures/feuilles/feuille1.png")
	_demo.scale = Vector2(1.2, 1.2)
	_demo.z_index = 5
	layer.add_child(_demo)
	var title := Label.new()
	title.text = tr("feels_lab")
	UiTheme.style_label(title, 40)
	UiLayout.place(title, 40, 40, 720, 50)
	add_child(title)
	for i in 6:
		var a := TAU * float(i) / 6.0
		_ring_targets.append(_center + Vector2(cos(a), sin(a)) * 110.0)
	var actions := [
		["Burst", _fx_burst],
		["Shock", _fx_shock],
		["Confetti", _fx_confetti],
		["Punch", _fx_punch],
		["Banner", _fx_banner],
		["Special", _fx_special],
		["Flutter", _fx_flutter],
		["Flip", _fx_flip],
		["Land shadow", _fx_land_shadow],
		["Parallax", _fx_parallax],
		["Match threads", _fx_match],
		["Tape sweep H", _fx_tape_h],
		["Tape sweep V", _fx_tape_v],
		["Foil rays", _fx_foil],
		["Wrap ring", _fx_wrap],
		["Plane trails", _fx_plane],
	]
	var scroll := ScrollContainer.new()
	UiLayout.place(scroll, 40, 100, 720, 1040)
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	for a in actions:
		var btn := Button.new()
		btn.text = str(a[0])
		btn.custom_minimum_size = Vector2(640, 56)
		UiTheme.style_button(btn)
		btn.pressed.connect(a[1])
		box.add_child(btn)
	var back := Button.new()
	back.text = tr("back")
	back.custom_minimum_size = Vector2(640, 56)
	UiTheme.style_button(back)
	back.pressed.connect(func(): GameFlow.go_main_menu())
	box.add_child(back)


func _process(delta: float) -> void:
	if _decor:
		_decor.scroll(delta, 0.35)


func _reset_demo() -> void:
	if _demo == null:
		return
	_demo.position = _center
	_demo.rotation = 0.0
	_demo.scale = Vector2(1.2, 1.2)
	_demo.modulate = Color.WHITE


func _fx_burst() -> void:
	_juice.burst_at(_center, 2, 24)


func _fx_shock() -> void:
	_juice.shockwave(_center, Color(1, 0.8, 0.4), 140.0)


func _fx_confetti() -> void:
	_juice.confetti(_center, 50)


func _fx_punch() -> void:
	_juice.camera_punch(10.0, 0.15, 3)


func _fx_banner() -> void:
	_juice.combo_banner(4)


func _fx_special() -> void:
	_juice.special_created(tr("special_bomb"), Color(0.5, 0.9, 1.0))


func _fx_flutter() -> void:
	_reset_demo()
	var from := _center + Vector2(0, -180)
	_demo.position = from
	_juice.fall_flutter(_demo, from, _center, 0.45)


func _fx_flip() -> void:
	_reset_demo()
	_juice.paper_flip(_demo, Vector2(1.2, 1.2), 0.35)


func _fx_land_shadow() -> void:
	_reset_demo()
	_juice.land_squash(_demo, Vector2(1.2, 1.2), 0.18)


func _fx_parallax() -> void:
	_juice.camera_punch(14.0, 0.2, 4)


func _fx_match() -> void:
	_juice.clear_telegraphs()
	_juice.telegraph_match(_ring_targets, Color(0.95, 0.55, 0.35), 0.35)


func _fx_tape_h() -> void:
	_juice.clear_telegraphs()
	_juice.telegraph_stripe(_center, true, 280.0, Color(0.95, 0.85, 0.45), 0.3)


func _fx_tape_v() -> void:
	_juice.clear_telegraphs()
	_juice.telegraph_stripe(_center, false, 280.0, Color(0.55, 0.9, 0.5), 0.3)


func _fx_foil() -> void:
	_juice.clear_telegraphs()
	_juice.telegraph_bomb(_center, _ring_targets, Color(0.4, 0.85, 1.0), 0.35)


func _fx_wrap() -> void:
	_juice.clear_telegraphs()
	_juice.telegraph_wrapped(_center, Color(1.0, 0.55, 0.85), 0.32, 90.0)


func _fx_plane() -> void:
	_juice.clear_telegraphs()
	_juice.telegraph_fish(_center, _ring_targets.slice(0, 3), Color(1.0, 0.9, 0.4), 0.32)
