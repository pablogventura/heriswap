extends Control


func _ready() -> void:
	var s: Dictionary = GameFlow.last_score
	$VBox/Result.text = tr("congrats") if SaveService.is_high_score(
		int(s.get("mode", 0)), int(s.get("difficulty", 0)),
		int(s.get("points", 0)), float(s.get("time", 0.0))
	) else ("Score: %d" % int(s.get("points", 0)))
	$VBox/Score.text = "Points: %d\nLevel: %d\nTime: %.1fs" % [
		int(s.get("points", 0)), int(s.get("level", 1)), float(s.get("time", 0.0))
	]
	var high := SaveService.is_high_score(
		int(s.get("mode", 0)), int(s.get("difficulty", 0)),
		int(s.get("points", 0)), float(s.get("time", 0.0))
	)
	$VBox/NameRow.visible = high
	$VBox/Save.pressed.connect(_save)
	$VBox/Skip.pressed.connect(_done)
	if not high:
		$VBox/Save.visible = false


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
	if not bool(SaveService.options.get("rate_never", false)) and int(SaveService.options.get("game_count", 0)) >= 3:
		GameFlow.go_rate_it()
	else:
		GameFlow.go_mode_menu()
