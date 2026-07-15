extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_buttons_in($VBox)
	$VBox/Text.text = "%s\n\n%s" % [tr("about_us"), tr("support_us")]
	$VBox/Donate.text = tr("support_us")
	$VBox/Donate.pressed.connect(func(): PlatformServices.purchase_donate())
	$VBox/Back.text = tr("back")
	$VBox/Back.pressed.connect(func(): GameFlow.go_main_menu())
