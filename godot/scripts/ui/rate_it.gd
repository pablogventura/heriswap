extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_button($Now)
	UiTheme.style_button($Later)
	UiTheme.style_button($Never)
	UiTheme.style_label($Text, 28)
	$Text.text = tr("please_rate_it")
	$Now.text = tr("rate_now")
	$Later.text = tr("rate_later")
	$Never.text = tr("rate_never")
	if not PlatformServices.can_show_rate():
		GameFlow.go_mode_menu()
		return
	$Now.pressed.connect(func():
		PlatformServices.show_rate_store()
		SaveService.options["rate_never"] = true
		SaveService.save_options()
		GameFlow.go_mode_menu()
	)
	$Later.pressed.connect(func():
		SaveService.options["rate_later_count"] = int(SaveService.options.get("rate_later_count", 0)) + 1
		SaveService.save_options()
		GameFlow.go_mode_menu()
	)
	$Never.pressed.connect(func():
		SaveService.options["rate_never"] = true
		SaveService.save_options()
		GameFlow.go_mode_menu()
	)
