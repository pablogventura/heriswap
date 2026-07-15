extends Control


func _ready() -> void:
	AudioBus.play_menu_music()
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
	if RunSnapshot.has_saved_run():
		$VBox/Continue.visible = true
		$VBox/Continue.pressed.connect(_continue_run)
	else:
		$VBox/Continue.visible = false


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
