extends Control


func _ready() -> void:
	$VBox/Text.text = tr("please_rate_it")
	$VBox/Now.text = tr("rate_now")
	$VBox/Later.text = tr("rate_later")
	$VBox/Never.text = tr("rate_never")
	if not PlatformServices.can_show_rate():
		GameFlow.go_mode_menu()
		return
	$VBox/Now.pressed.connect(func():
		PlatformServices.show_rate_store()
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
