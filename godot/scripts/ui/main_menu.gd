extends Control


func _ready() -> void:
	AudioBus.play_menu_music()
	UiTheme.apply_layered_menu_bg(self)
	UiTheme.style_label($Title, 56)
	UiTheme.style_buttons_in($Panel)
	var logo := "res://assets/textures/logo/soupe_logo.png"
	if ResourceLoader.exists(logo):
		$Brand.texture = load(logo)
	$Title.text = "Heriswap"
	$Panel/Play.text = tr("play")
	$Panel/About.text = tr("about_us")
	$Panel/Quit.text = tr("quit")
	$Panel/Continue.text = tr("continue_")
	$Panel/Play.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.go_mode_menu()
	)
	$Panel/About.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.go_about()
	)
	$Panel/Sound.pressed.connect(_toggle_sound)
	$Panel/Quit.pressed.connect(func(): get_tree().quit())
	UiTheme.add_sac_button(self, func():
		AudioBus.play_click()
		GameFlow.go_about()
	, 40.0, 1100.0)
	_refresh_sound()
	_ensure_locale()
	if RunSnapshot.has_saved_run():
		$Panel/Continue.visible = true
		if not $Panel/Continue.pressed.is_connected(_continue_run):
			$Panel/Continue.pressed.connect(_continue_run)
	else:
		$Panel/Continue.visible = false


func _ensure_locale() -> void:
	var loc: OptionButton = $Panel/Locale
	if loc.item_count == 0:
		for code in ["en", "es", "fr", "de", "it", "pt_BR", "ru", "ja", "nl", "pl", "tr", "el", "gl", "ms", "nb"]:
			loc.add_item(code)
	UiTheme.style_button(loc)
	var current := str(SaveService.options.get("locale", "en"))
	for i in loc.item_count:
		if loc.get_item_text(i) == current:
			loc.select(i)
			break
	if not loc.item_selected.is_connected(_on_locale):
		loc.item_selected.connect(_on_locale)


func _on_locale(i: int) -> void:
	var loc: OptionButton = $Panel/Locale
	LocaleService.set_locale(loc.get_item_text(i))
	$Panel/Play.text = tr("play")
	$Panel/About.text = tr("about_us")
	$Panel/Quit.text = tr("quit")
	$Panel/Continue.text = tr("continue_")
	_refresh_sound()


func _toggle_sound() -> void:
	SaveService.set_sound(not SaveService.is_sound_on())
	_refresh_sound()
	AudioBus.play_click()


func _refresh_sound() -> void:
	$Panel/Sound.text = tr("sound_on") if SaveService.is_sound_on() else tr("sound_off")


func _continue_run() -> void:
	var data := RunSnapshot.load_run()
	if data.is_empty():
		return
	GameFlow.selected_mode = int(data.get("mode", 0))
	GameFlow.selected_difficulty = int(data.get("difficulty", 0))
	GameFlow.go_match()
