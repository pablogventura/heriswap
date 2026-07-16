extends Control

## Pre-level craft tray: pick free boosters with clear craft icons.


func _ready() -> void:
	AudioBus.play_menu_music()
	UiTheme.apply_layered_menu_bg(self)
	var title := Label.new()
	title.text = tr("craft_tray")
	UiTheme.style_label(title, 42)
	UiLayout.place(title, 40, 50, 720, 60)
	add_child(title)
	var hint := Label.new()
	hint.text = tr("booster_use")
	UiTheme.style_label(hint, 22)
	hint.modulate = Color(1, 1, 1, 0.75)
	UiLayout.place(hint, 40, 105, 720, 36)
	add_child(hint)

	var kinds := [
		[BoosterInventory.KIND_SCISSORS, "booster_scissors", "scissors"],
		[BoosterInventory.KIND_FREE_SWAP, "booster_free_swap", "swap"],
		[BoosterInventory.KIND_CONFETTI_BAG, "booster_confetti", "bag"],
		[BoosterInventory.KIND_PLUS_MOVES, "booster_plus_moves", "plus"],
	]
	var y := 160.0
	var row_btns: Array = []
	for row in kinds:
		var kind: String = row[0]
		var key: String = row[1]
		var icon_id: String = row[2]
		var n: int = int(GameFlow.boosters.counts.get(kind, 0))
		var panel := _make_booster_row(kind, key, icon_id, n, y, row_btns)
		add_child(panel)
		y += 100.0

	var play := Button.new()
	play.text = tr("play")
	UiTheme.style_button(play)
	UiLayout.place(play, 80, y + 30, 640, 72)
	play.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.go_countdown()
	)
	add_child(play)
	var skip := Button.new()
	skip.text = tr("skip")
	UiTheme.style_button(skip)
	UiLayout.place(skip, 80, y + 120, 640, 64)
	skip.pressed.connect(func():
		GameFlow.selected_booster = ""
		GameFlow.go_countdown()
	)
	add_child(skip)


func _make_booster_row(kind: String, key: String, icon_id: String, count: int, y: float, row_btns: Array) -> Control:
	var panel := PanelContainer.new()
	UiLayout.place(panel, 60, y, 680, 88)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.9, 0.78, 0.92)
	style.border_color = Color(0.45, 0.32, 0.18, 0.85)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	panel.add_child(h)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _booster_icon_texture(icon_id)
	h.add_child(icon)

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.text = "%s\nx%d" % [tr(key), count]
	UiTheme.style_label(lbl, 26)
	lbl.add_theme_color_override("font_color", Color(0.25, 0.18, 0.12))
	h.add_child(lbl)

	var btn := Button.new()
	btn.text = "✓" if count > 0 else "-"
	btn.disabled = count <= 0
	btn.custom_minimum_size = Vector2(100, 56)
	UiTheme.style_button(btn)
	h.add_child(btn)

	row_btns.append({"panel": panel, "style": style, "kind": kind, "btn": btn})
	btn.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.selected_booster = kind
		for info in row_btns:
			var st: StyleBoxFlat = info.style
			if info.kind == kind:
				st.border_color = Color(0.95, 0.65, 0.2, 1.0)
				st.set_border_width_all(5)
				st.bg_color = Color(1.0, 0.95, 0.7, 0.98)
				info.panel.modulate = Color(1.08, 1.05, 0.95)
			else:
				st.border_color = Color(0.45, 0.32, 0.18, 0.85)
				st.set_border_width_all(3)
				st.bg_color = Color(0.95, 0.9, 0.78, 0.92)
				info.panel.modulate = Color.WHITE
	)
	return panel


func _booster_icon_texture(icon_id: String) -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match icon_id:
		"scissors":
			_draw_line_thick(img, Vector2(18, 14), Vector2(46, 50), Color(0.35, 0.4, 0.45), 3)
			_draw_line_thick(img, Vector2(46, 14), Vector2(18, 50), Color(0.35, 0.4, 0.45), 3)
			_fill_circle(img, Vector2(18, 14), 7, Color(0.85, 0.35, 0.4))
			_fill_circle(img, Vector2(46, 14), 7, Color(0.85, 0.35, 0.4))
			_fill_circle(img, Vector2(32, 32), 4, Color(0.55, 0.5, 0.35))
		"swap":
			_draw_line_thick(img, Vector2(14, 28), Vector2(50, 28), Color(0.3, 0.55, 0.75), 4)
			_draw_line_thick(img, Vector2(42, 18), Vector2(50, 28), Color(0.3, 0.55, 0.75), 4)
			_draw_line_thick(img, Vector2(42, 38), Vector2(50, 28), Color(0.3, 0.55, 0.75), 4)
			_draw_line_thick(img, Vector2(50, 40), Vector2(14, 40), Color(0.75, 0.45, 0.25), 4)
			_draw_line_thick(img, Vector2(22, 30), Vector2(14, 40), Color(0.75, 0.45, 0.25), 4)
			_draw_line_thick(img, Vector2(22, 50), Vector2(14, 40), Color(0.75, 0.45, 0.25), 4)
		"bag":
			_fill_rect(img, Rect2i(22, 22, 20, 28), Color(0.55, 0.35, 0.7))
			_fill_rect(img, Rect2i(20, 18, 24, 8), Color(0.7, 0.5, 0.85))
			_fill_circle(img, Vector2(28, 14), 3, Color(1.0, 0.45, 0.55))
			_fill_circle(img, Vector2(36, 12), 3, Color(1.0, 0.85, 0.35))
			_fill_circle(img, Vector2(42, 16), 3, Color(0.4, 0.85, 0.95))
			_fill_circle(img, Vector2(32, 20), 2, Color(0.55, 0.95, 0.5))
		"plus":
			_fill_rect(img, Rect2i(28, 14, 8, 36), Color(0.25, 0.65, 0.4))
			_fill_rect(img, Rect2i(14, 28, 36, 8), Color(0.25, 0.65, 0.4))
			_fill_circle(img, Vector2(48, 16), 8, Color(0.95, 0.75, 0.25))
		_:
			_fill_circle(img, Vector2(32, 32), 16, Color(0.7, 0.7, 0.7))
	return ImageTexture.create_from_image(img)


func _fill_circle(img: Image, c: Vector2, r: float, col: Color) -> void:
	var rr := int(r)
	for y in range(-rr, rr + 1):
		for x in range(-rr, rr + 1):
			if Vector2(x, y).length() <= r:
				var px := int(c.x) + x
				var py := int(c.y) + y
				if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
					img.set_pixel(px, py, col)


func _fill_rect(img: Image, r: Rect2i, col: Color) -> void:
	for y in range(r.position.y, r.position.y + r.size.y):
		for x in range(r.position.x, r.position.x + r.size.x):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, col)


func _draw_line_thick(img: Image, a: Vector2, b: Vector2, col: Color, thickness: int) -> void:
	var steps := int(a.distance_to(b)) + 1
	for i in steps:
		var p := a.lerp(b, float(i) / float(maxi(1, steps - 1)))
		_fill_circle(img, p, float(thickness) * 0.5, col)
