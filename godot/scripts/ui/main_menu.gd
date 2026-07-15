extends Control


func _ready() -> void:
	AudioBus.play_menu_music()
	UiTheme.apply_backdrop(self)
	UiTheme.style_buttons_in($VBox)
	$VBox/Play.text = tr("play")
	$VBox/About.text = tr("about_us")
	$VBox/Quit.text = tr("quit")
	$VBox/Continue.text = tr("continue_")
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
	_ensure_locale()
	if RunSnapshot.has_saved_run():
		$VBox/Continue.visible = true
		if not $VBox/Continue.pressed.is_connected(_continue_run):
			$VBox/Continue.pressed.connect(_continue_run)
	else:
		$VBox/Continue.visible = false


func _ensure_locale() -> void:
	var loc: OptionButton = $VBox.get_node_or_null("Locale") as OptionButton
	if loc == null:
		loc = OptionButton.new()
		loc.name = "Locale"
		for code in ["en", "es", "fr", "de", "it", "pt_BR", "ru", "ja", "nl", "pl", "tr", "el", "gl", "ms", "nb"]:
			loc.add_item(code)
		$VBox.add_child(loc)
		$VBox.move_child(loc, 3)
		UiTheme.style_button(loc)
	var current := str(SaveService.options.get("locale", "en"))
	for i in loc.item_count:
		if loc.get_item_text(i) == current:
			loc.select(i)
			break
	if not loc.item_selected.is_connected(_on_locale):
		loc.item_selected.connect(_on_locale)


func _on_locale(i: int) -> void:
	var loc: OptionButton = $VBox/Locale
	LocaleService.set_locale(loc.get_item_text(i))
	$VBox/Play.text = tr("play")
	$VBox/About.text = tr("about_us")
	$VBox/Quit.text = tr("quit")
	$VBox/Continue.text = tr("continue_")
	_refresh_sound()


func _toggle_sound() -> void:
	SaveService.set_sound(not SaveService.is_sound_on())
	_refresh_sound()
	AudioBus.play_click()


func _refresh_sound() -> void:
	$VBox/Sound.text = tr("sound_on") if SaveService.is_sound_on() else tr("sound_off")


func _continue_run() -> void:
	var data := RunSnapshot.load_run()
	if data.is_empty():
		return
	GameFlow.selected_mode = int(data.get("mode", 0))
	GameFlow.selected_difficulty = int(data.get("difficulty", 0))
	GameFlow.go_match()
