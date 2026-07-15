extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_button($Save)
	UiTheme.style_button($Skip)
	UiTheme.style_label($Result, 36)
	UiTheme.style_label($Score, 24)
	var s: Dictionary = GameFlow.last_score
	var high := SaveService.is_high_score(
		int(s.get("mode", 0)), int(s.get("difficulty", 0)),
		int(s.get("points", 0)), float(s.get("time", 0.0))
	)
	$Result.text = tr("congrats") if high else ("%s: %d" % [tr("score"), int(s.get("points", 0))])
	$Score.text = "%s: %d\n%s: %d\n%.1fs" % [
		tr("score"), int(s.get("points", 0)), tr("level"), int(s.get("level", 1)), float(s.get("time", 0.0))
	]
	var digits := AlphabetDigits.new()
	digits.glyph_height = 48.0
	$ScoreDigits.add_child(digits)
	digits.set_display(str(int(s.get("points", 0))))
	$NameRow.visible = high
	$NameRow/NameEdit.placeholder_text = tr("enter_name")
	$Save.text = tr("save_name")
	$Skip.text = tr("continue_")
	$Save.pressed.connect(_save)
	$Skip.pressed.connect(_done)
	if not high:
		$Save.visible = false
		$Reuse.visible = false
	else:
		_fill_name_reuse()
	Achievements.s_beat_top(
		int(s.get("mode", 0)), int(s.get("difficulty", 0)),
		int(s.get("points", 0)), float(s.get("time", 0.0))
	)


func _fill_name_reuse() -> void:
	var reuse: OptionButton = $Reuse
	reuse.clear()
	reuse.add_item(tr("reuse_name"))
	var names := {}
	for e in SaveService.load_scores():
		names[str(e.name)] = true
	for n in names.keys():
		reuse.add_item(n)
	UiTheme.style_button(reuse)
	reuse.item_selected.connect(func(i):
		if i > 0:
			$NameRow/NameEdit.text = reuse.get_item_text(i)
	)


func _save() -> void:
	var s: Dictionary = GameFlow.last_score.duplicate()
	s["name"] = $NameRow/NameEdit.text.strip_edges()
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
