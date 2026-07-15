extends Control

var mode: int = 0
var difficulty: int = Difficulty.EASY
var _digits: AlphabetDigits


func _ready() -> void:
	UiTheme.apply_backdrop(self, UiTheme.MODE_BG)
	for n in ["ModeNormal", "ModeTiles", "Mode100", "DiffEasy", "DiffMedium", "DiffHard", "Help", "Play", "Back"]:
		UiTheme.style_button(get_node(n) as BaseButton)
	UiTheme.style_label($ModeLabel, 36)
	UiTheme.style_label($DiffLabel, 26)
	UiTheme.style_label($ScoresTitle, 28)
	UiTheme.style_label($Scores, 20)
	$ModeNormal.text = tr("mode_1")
	$ModeTiles.text = tr("mode_2")
	$Mode100.text = tr("mode_3")
	$DiffEasy.text = tr("diff_1")
	$DiffMedium.text = tr("diff_2")
	$DiffHard.text = tr("diff_3")
	$Help.text = tr("help")
	$Play.text = tr("play")
	$Back.text = tr("quit")
	$ScoresTitle.text = tr("score")
	$ModeNormal.pressed.connect(func(): _set_mode(0))
	$ModeTiles.pressed.connect(func(): _set_mode(1))
	$Mode100.pressed.connect(func(): _set_mode(2))
	$DiffEasy.pressed.connect(func(): _set_diff(Difficulty.EASY))
	$DiffMedium.pressed.connect(func(): _set_diff(Difficulty.MEDIUM))
	$DiffHard.pressed.connect(func(): _set_diff(Difficulty.HARD))
	$Help.pressed.connect(func(): GameFlow.go_help())
	$Play.pressed.connect(_play)
	$Back.pressed.connect(func(): GameFlow.go_main_menu())
	_digits = AlphabetDigits.new()
	_digits.name = "Digits"
	_digits.glyph_height = 40.0
	$ScoreDigits.add_child(_digits)
	_refresh()
	_refresh_scores()


func _set_mode(m: int) -> void:
	mode = m
	AudioBus.play_click()
	_refresh()
	_refresh_scores()


func _set_diff(d: int) -> void:
	difficulty = d
	AudioBus.play_click()
	_refresh()
	_refresh_scores()


func _refresh() -> void:
	$ModeLabel.text = tr(["mode_1", "mode_2", "mode_3"][mode])
	$DiffLabel.text = tr(Difficulty.label_key(difficulty))


func _refresh_scores() -> void:
	var top := SaveService.get_top5(mode, difficulty)
	var lines: PackedStringArray = []
	var sum_pts := 0
	var best := 0
	for s in top:
		sum_pts += int(s.points)
		best = maxi(best, int(s.points))
		if mode == 1:
			lines.append("%s  %.1fs" % [s.name, float(s.time)])
		else:
			lines.append("%s  %d" % [s.name, int(s.points)])
	if top.size() > 0:
		lines.append("%s %d" % [tr("average_score"), int(float(sum_pts) / float(top.size()))])
	$Scores.text = "\n".join(lines) if not lines.is_empty() else "-"
	if _digits:
		_digits.set_display(str(best) if top.size() > 0 else "0")


func _all_top_over_100k() -> bool:
	var top := SaveService.get_top5(mode, difficulty)
	if top.size() < 5:
		return false
	for s in top:
		if int(s.points) < 100000:
			return false
	return true


func _play() -> void:
	AudioBus.play_click()
	GameFlow.selected_mode = mode
	GameFlow.selected_difficulty = difficulty
	var scores := SaveService.get_top5(mode, difficulty)
	if scores.is_empty():
		GameFlow.go_help()
		return
	if mode == 0 and _all_top_over_100k():
		GameFlow.go_start_at_10()
	else:
		GameFlow.begin_run(mode, difficulty, 1)
