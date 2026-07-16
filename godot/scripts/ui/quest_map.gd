extends Control

## Corkboard quest map - ScrapSwap primary path.


func _ready() -> void:
	AudioBus.play_menu_music()
	UiTheme.apply_layered_menu_bg(self)
	var title := Label.new()
	title.name = "Title"
	title.text = tr("quest")
	UiTheme.style_label(title, 48)
	UiLayout.place(title, 40, 40, 720, 70)
	add_child(title)
	var pack := LevelCatalog.load_pack()
	var progress: int = int(SaveService.options.get("quest_index", 0))
	var y := 120.0
	for i in pack.size():
		var lv: Dictionary = pack[i]
		if bool(lv.get("zen", false)):
			continue
		var btn := Button.new()
		var locked := i > progress
		btn.text = "%d. %s" % [i + 1, tr(str(lv.get("name_key", lv.get("id", "level"))))]
		btn.disabled = locked
		UiTheme.style_button(btn)
		UiLayout.place(btn, 80, y, 640, 58)
		var idx := i
		btn.pressed.connect(func():
			AudioBus.play_click()
			GameFlow.begin_quest_level(idx)
		)
		add_child(btn)
		y += 66.0
	var daily := Button.new()
	daily.text = tr("daily_desk")
	if DailyDesk.already_claimed(SaveService.options):
		daily.text = "%s ✓" % tr("daily_desk")
	UiTheme.style_button(daily)
	UiLayout.place(daily, 80, y + 10, 640, 58)
	daily.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.begin_daily()
	)
	add_child(daily)
	var arcade := Button.new()
	arcade.text = tr("arcade")
	UiTheme.style_button(arcade)
	UiLayout.place(arcade, 80, y + 80, 640, 58)
	arcade.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.go_mode_menu()
	)
	add_child(arcade)
	var codex := Button.new()
	codex.text = tr("scrap_codex")
	UiTheme.style_button(codex)
	UiLayout.place(codex, 80, y + 150, 640, 58)
	codex.pressed.connect(func():
		AudioBus.play_click()
		GameFlow.go_codex()
	)
	add_child(codex)
	var back := Button.new()
	back.text = tr("back")
	UiTheme.style_button(back)
	UiLayout.place(back, 80, 1180, 640, 64)
	back.pressed.connect(func(): GameFlow.go_main_menu())
	add_child(back)
