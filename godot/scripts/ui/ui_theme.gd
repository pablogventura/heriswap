class_name UiTheme
extends RefCounted

const BTN := "res://assets/textures/menu/fond_bouton.png"
const BACK := "res://assets/textures/menu/back.png"
const MODE_BG := "res://assets/textures/menu/fond_menu_mode.png"
const SAC := "res://assets/textures/menu/sac.png"
const PLAN1 := "res://assets/textures/menu/1erplan.png"
const PLAN2 := "res://assets/textures/menu/2emeplan.png"
const FONT := "res://assets/fonts/FreeMono.ttf"


static func font() -> Font:
	if ResourceLoader.exists(FONT):
		return load(FONT) as Font
	return ThemeDB.fallback_font


static func label_settings(size: int = 28, color: Color = Color.WHITE) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = font()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 2
	ls.outline_color = Color(0, 0, 0, 0.55)
	return ls


static func apply_backdrop(root: Control, path: String = BACK) -> void:
	if root.has_node("ThemedBg"):
		return
	var bg := TextureRect.new()
	bg.name = "ThemedBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		bg.texture = load(path)
	root.add_child(bg)
	root.move_child(bg, 0)


static func apply_layered_menu_bg(root: Control) -> void:
	if root.has_node("ThemedBg"):
		return
	apply_backdrop(root, BACK)
	if ResourceLoader.exists(PLAN2):
		var p2 := TextureRect.new()
		p2.name = "Plan2"
		p2.set_anchors_preset(Control.PRESET_FULL_RECT)
		p2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		p2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p2.texture = load(PLAN2)
		p2.modulate = Color(1, 1, 1, 0.85)
		root.add_child(p2)
		root.move_child(p2, 1)
	if ResourceLoader.exists(PLAN1):
		var p1 := TextureRect.new()
		p1.name = "Plan1"
		p1.set_anchors_preset(Control.PRESET_FULL_RECT)
		p1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		p1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p1.texture = load(PLAN1)
		p1.modulate = Color(1, 1, 1, 0.7)
		root.add_child(p1)
		root.move_child(p1, 2)


static func add_sac_button(root: Control, cb: Callable, x: float = 40.0, y: float = 1080.0) -> TextureButton:
	if root.has_node("SacAbout"):
		return root.get_node("SacAbout") as TextureButton
	var btn := TextureButton.new()
	btn.name = "SacAbout"
	if ResourceLoader.exists(SAC):
		var tex: Texture2D = load(SAC)
		btn.texture_normal = tex
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	UiLayout.place(btn, x, y, 140.0, 140.0)
	btn.pressed.connect(cb)
	root.add_child(btn)
	return btn


static func style_button(btn: BaseButton) -> void:
	if not ResourceLoader.exists(BTN):
		_style_button_font(btn)
		return
	var tex: Texture2D = load(BTN)
	var normal := StyleBoxTexture.new()
	normal.texture = tex
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxTexture
	hover.modulate_color = Color(1.12, 1.12, 1.05, 1.0)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxTexture
	pressed.modulate_color = Color(0.88, 0.88, 0.82, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)
	_style_button_font(btn)


static func _style_button_font(btn: BaseButton) -> void:
	btn.add_theme_font_override("font", font())
	btn.add_theme_font_size_override("font_size", 24)
	# Ink on cream paper labels.
	btn.add_theme_color_override("font_color", Color(0.22, 0.16, 0.12))
	btn.add_theme_color_override("font_hover_color", Color(0.14, 0.1, 0.08))
	btn.add_theme_color_override("font_pressed_color", Color(0.3, 0.22, 0.14))


static func style_label(label: Label, size: int = 28) -> void:
	label.label_settings = label_settings(size)


static func style_buttons_in(node: Node) -> void:
	for c in node.get_children():
		if c is BaseButton:
			style_button(c)
			wire_button_punch(c)
		elif c is Label:
			style_label(c, 24)
		style_buttons_in(c)


static func wire_button_punch(btn: BaseButton) -> void:
	if btn.has_meta("punch_wired"):
		return
	btn.set_meta("punch_wired", true)
	btn.button_down.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
	)
	btn.button_up.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
