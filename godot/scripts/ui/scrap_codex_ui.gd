extends Control

## Scrap Codex unlock gallery.


func _ready() -> void:
	AudioBus.play_menu_music()
	UiTheme.apply_layered_menu_bg(self)
	var title := Label.new()
	title.text = tr("scrap_codex")
	UiTheme.style_label(title, 44)
	UiLayout.place(title, 40, 40, 720, 60)
	add_child(title)
	var scroll := ScrollContainer.new()
	UiLayout.place(scroll, 40, 120, 720, 950)
	add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	for id in GameFlow.scrap_codex.list_unlocked():
		var lbl := Label.new()
		lbl.text = "• %s" % str(id)
		UiTheme.style_label(lbl, 28)
		box.add_child(lbl)
	var back := Button.new()
	back.text = tr("back")
	UiTheme.style_button(back)
	UiLayout.place(back, 80, 1180, 640, 64)
	back.pressed.connect(func(): GameFlow.go_quest_map())
	add_child(back)
