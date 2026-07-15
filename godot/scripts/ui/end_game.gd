extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_buttons_in($VBox)
	var s: Dictionary = GameFlow.last_score
	var high := SaveService.is_high_score(
		int(s.get("mode", 0)), int(s.get("difficulty", 0)),
		int(s.get("points", 0)), float(s.get("time", 0.0))
	)
	$VBox/Result.text = tr("congrats") if high else ("%s: %d" % [tr("score"), int(s.get("points", 0))])
	$VBox/Score.text = "%s: %d\n%s: %d\n%.1fs" % [
		tr("score"), int(s.get("points", 0)), tr("level"), int(s.get("level", 1)), float(s.get("time", 0.0))
	]
	$VBox/NameRow.visible = high
	$VBox/NameRow/NameEdit.placeholder_text = tr("enter_name")
	$VBox/Save.text = tr("save_name")
	$VBox/Skip.text = tr("continue_")
	$VBox/Save.pressed.connect(_save)
	$VBox/Skip.pressed.connect(_done)
	if not high:
		$VBox/Save.visible = false
	else:
		_fill_name_reuse()
	Achievements.s_beat_top(
		int(s.get("mode", 0)), int(s.get("difficulty", 0)),
		int(s.get("points", 0)), float(s.get("time", 0.0))
	)


func _fill_name_reuse() -> void:
	if $VBox.has_node("Reuse"):
		return
	var reuse := OptionButton.new()
	reuse.name = "Reuse"
	reuse.add_item(tr("reuse_name"))
	var names := {}
	for e in SaveService.load_scores():
		names[str(e.name)] = true
	for n in names.keys():
		reuse.add_item(n)
	$VBox.add_child(reuse)
	$VBox.move_child(reuse, 3)
	reuse.item_selected.connect(func(i):
		if i > 0:
			$VBox/NameRow/NameEdit.text = reuse.get_item_text(i)
	)


func _save() -> void:
	var s: Dictionary = GameFlow.last_score.duplicate()
	s["name"] = $VBox/NameRow/NameEdit.text.strip_edges()
	if s["name"] == "":
		s["name"] = "Hero"
	SaveService.add_score(s)
	_finish_flow()


func _done() -> void:
	_finish_flow()


func _finish_flow() -> void:
	GameFlow.returning_from_match = true
	if PlatformServices.can_show_rate() and not bool(SaveService.options.get("rate_never", false)) and int(SaveService.options.get("game_count", 0)) >= 3:
		GameFlow.go_rate_it()
	else:
		GameFlow.go_mode_menu()
