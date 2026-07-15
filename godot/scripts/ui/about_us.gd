extends Control


func _ready() -> void:
	UiTheme.apply_layered_menu_bg(self)
	UiTheme.style_button($Donate)
	UiTheme.style_button($Back)
	UiTheme.style_label($Text, 26)
	if ResourceLoader.exists(UiTheme.SAC):
		$Sac.texture = load(UiTheme.SAC)
	$Text.text = "%s\n\n%s" % [tr("about_us"), tr("support_us")]
	$Donate.text = tr("support_us")
	$Donate.pressed.connect(func(): PlatformServices.purchase_donate())
	$Back.text = tr("back")
	$Back.pressed.connect(func(): GameFlow.go_main_menu())
