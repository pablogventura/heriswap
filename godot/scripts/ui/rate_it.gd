extends Control


func _ready() -> void:
	$VBox/Text.text = tr("please_rate_it")
	$VBox/Now.pressed.connect(func():
		PlatformServices.open_url("https://play.google.com/store/apps/details?id=net.damsy.soupeaucaillou.heriswap2")
		SaveService.options["rate_never"] = true
		SaveService.save_options()
		GameFlow.go_mode_menu()
	)
	$VBox/Later.pressed.connect(func():
		SaveService.options["rate_later_count"] = int(SaveService.options.get("rate_later_count", 0)) + 1
		SaveService.save_options()
		GameFlow.go_mode_menu()
	)
	$VBox/Never.pressed.connect(func():
		SaveService.options["rate_never"] = true
		SaveService.save_options()
		GameFlow.go_mode_menu()
	)
