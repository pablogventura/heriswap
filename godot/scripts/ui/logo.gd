extends Control


func _ready() -> void:
	UiTheme.apply_layered_menu_bg(self)
	UiTheme.style_label($Title, 64)
	UiTheme.style_label($Subtitle, 24)
	$Title.text = "Heriswap"
	$Subtitle.text = ""
	var tex_path := "res://assets/textures/logo/soupe_logo.png"
	if ResourceLoader.exists(tex_path):
		$LogoImg.texture = load(tex_path)
	await get_tree().create_timer(1.4).timeout
	GameFlow.go_main_menu()
