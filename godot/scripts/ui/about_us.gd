extends Control


func _ready() -> void:
	UiTheme.apply_layered_menu_bg(self)
	UiTheme.style_button($Donate)
	UiTheme.style_button($Back)
	UiTheme.style_label($Text, 24)
	if ResourceLoader.exists(UiTheme.SAC):
		$Sac.texture = load(UiTheme.SAC)
	$Text.text = "%s\n\n%s\n\n%s\n%s" % [
		tr("credits_title"),
		tr("credits_body"),
		tr("about_us"),
		tr("support_us"),
	]
	$Donate.text = tr("support_us")
	$Donate.pressed.connect(func(): PlatformServices.purchase_donate())
	$Back.text = tr("back")
	$Back.pressed.connect(func(): GameFlow.go_main_menu())
	_ensure_extra_buttons()


func _ensure_extra_buttons() -> void:
	if has_node("ExportSave"):
		return
	var export_btn := Button.new()
	export_btn.name = "ExportSave"
	export_btn.text = tr("export_save")
	UiTheme.style_button(export_btn)
	UiLayout.place(export_btn, 80, 980, 300, 56)
	export_btn.pressed.connect(func():
		DisplayServer.clipboard_set(SaveService.export_save_blob())
		AudioBus.play_click()
	)
	add_child(export_btn)
	var feels := Button.new()
	feels.name = "Feels"
	feels.text = tr("feels_lab")
	UiTheme.style_button(feels)
	UiLayout.place(feels, 420, 980, 300, 56)
	feels.pressed.connect(func(): GameFlow.go_feels())
	add_child(feels)
	var motion := Button.new()
	motion.name = "ReduceMotion"
	motion.text = tr("reduce_motion")
	UiTheme.style_button(motion)
	UiLayout.place(motion, 80, 1050, 640, 56)
	motion.pressed.connect(func():
		var on := not bool(SaveService.options.get("reduce_motion", false))
		SaveService.options["reduce_motion"] = on
		SaveService.save_options()
		motion.modulate = Color(0.7, 1.0, 0.7) if on else Color.WHITE
		AudioBus.play_click()
	)
	add_child(motion)
