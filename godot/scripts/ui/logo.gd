extends Control


func _ready() -> void:
	$Center/Title.text = "Heriswap"
	$Center/Subtitle.text = ""
	UiTheme.apply_backdrop(self)
	UiTheme.style_label($Center/Title, 56)
	var tex_path := "res://assets/textures/logo/soupe_logo.png"
	if ResourceLoader.exists(tex_path) and not has_node("Center/LogoImg"):
		var img := TextureRect.new()
		img.name = "LogoImg"
		img.texture = load(tex_path)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.custom_minimum_size = Vector2(420, 260)
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Center.add_child(img)
		$Center.move_child(img, 0)
	await get_tree().create_timer(1.4).timeout
	GameFlow.go_main_menu()
