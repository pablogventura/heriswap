extends Control


func _ready() -> void:
	AudioBus.play_menu_music()
	$VBox/Play.text = tr("play")
	$VBox/About.text = tr("about_us")
	$VBox/Quit.text = tr("quit")
	$VBox/Play.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.go_mode_menu()
	)
	$VBox/About.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.go_about()
	)
	$VBox/Sound.pressed.connect(_toggle_sound)
	$VBox/Quit.pressed.connect(func(): get_tree().quit())
	_refresh_sound()
	if not $VBox.has_node("Locale"):
		var loc := OptionButton.new()
		loc.name = "Locale"
		for code in ["en", "es", "fr", "de", "it", "pt_BR", "ru", "ja", "nl", "pl", "tr", "el", "gl", "ms", "nb"]:
			loc.add_item(code)
		$VBox.add_child(loc)
		$VBox.move_child(loc, 3)
		var current := str(SaveService.options.get("locale", "en"))
		for i in loc.item_count:
			if loc.get_item_text(i) == current:
				loc.select(i)
				break
		loc.item_selected.connect(func(i):
			LocaleService.set_locale(loc.get_item_text(i))
			_ready_labels()
		)
	if RunSnapshot.has_saved_run():
		$VBox/Continue.visible = true
		$VBox/Continue.text = tr("continue_")
		if not $VBox/Continue.pressed.is_connected(_continue_run):
			$VBox/Continue.pressed.connect(_continue_run)
	else:
		$VBox/Continue.visible = false
	_style_background()


func _ready_labels() -> void:
	$VBox/Play.text = tr("play")
	$VBox/About.text = tr("about_us")
	$VBox/Quit.text = tr("quit")
	_refresh_sound()


func _style_background() -> void:
	if has_node("Bg"):
		return
	var bg := TextureRect.new()
	bg.name = "Bg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var path := "res://assets/textures/menu/back.png"
	if ResourceLoader.exists(path):
		bg.texture = load(path)
	add_child(bg)
	move_child(bg, 0)


func _toggle_sound() -> void:
	SaveService.set_sound(not SaveService.is_sound_on())
	_refresh_sound()
	AudioBus.play_click()


func _refresh_sound() -> void:
	$VBox/Sound.text = "Sound: ON" if SaveService.is_sound_on() else "Sound: OFF"


func _continue_run() -> void:
	var data := RunSnapshot.load_run()
	if data.is_empty():
		return
	GameFlow.selected_mode = int(data.get("mode", 0))
	GameFlow.selected_difficulty = int(data.get("difficulty", 0))
	GameFlow.go_match()
