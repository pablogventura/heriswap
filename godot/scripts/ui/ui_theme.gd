class_name UiTheme
extends RefCounted

const BTN := "res://assets/textures/menu/fond_bouton.png"
const BACK := "res://assets/textures/menu/back.png"
const MODE_BG := "res://assets/textures/menu/fond_menu_mode.png"
const FONT := "res://assets/fonts/FreeMono.ttf"


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


static func style_button(btn: BaseButton) -> void:
	if not ResourceLoader.exists(BTN):
		return
	var tex: Texture2D = load(BTN)
	var normal := StyleBoxTexture.new()
	normal.texture = tex
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxTexture
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	if ResourceLoader.exists(FONT):
		btn.add_theme_font_override("font", load(FONT))
		btn.add_theme_font_size_override("font_size", 22)


static func style_label(label: Label, size: int = 28) -> void:
	if ResourceLoader.exists(FONT):
		label.add_theme_font_override("font", load(FONT))
		label.add_theme_font_size_override("font_size", size)


static func style_buttons_in(node: Node) -> void:
	for c in node.get_children():
		if c is BaseButton:
			style_button(c)
		elif c is Label:
			style_label(c, 24)
		style_buttons_in(c)
