extends Control


func _ready() -> void:
	$VBox/Text.text = "%s\n\n%s" % [tr("about_us"), tr("support_us")]
	$VBox/Donate.pressed.connect(func(): PlatformServices.purchase_donate())
	$VBox/Back.pressed.connect(func(): GameFlow.go_main_menu())
