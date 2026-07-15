extends Control

var mode: int = 0
var difficulty: int = Difficulty.EASY


func _ready() -> void:
	$VBox/ModeNormal.text = tr("mode_1")
	$VBox/ModeTiles.text = tr("mode_2")
	$VBox/Mode100.text = tr("mode_3")
	$VBox/DiffEasy.text = tr("diff_1")
	$VBox/DiffMedium.text = tr("diff_2")
	$VBox/DiffHard.text = tr("diff_3")
	$VBox/Help.text = tr("help")
	$VBox/Play.text = tr("play")
	$VBox/ModeNormal.pressed.connect(func(): _set_mode(0))
	$VBox/ModeTiles.pressed.connect(func(): _set_mode(1))
	$VBox/Mode100.pressed.connect(func(): _set_mode(2))
	$VBox/DiffEasy.pressed.connect(func(): _set_diff(Difficulty.EASY))
	$VBox/DiffMedium.pressed.connect(func(): _set_diff(Difficulty.MEDIUM))
	$VBox/DiffHard.pressed.connect(func(): _set_diff(Difficulty.HARD))
	$VBox/Help.pressed.connect(func(): GameFlow.go_help())
	$VBox/Play.pressed.connect(_play)
	$VBox/Back.pressed.connect(func(): GameFlow.go_main_menu())
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
	$VBox/ModeLabel.text = tr(["mode_1", "mode_2", "mode_3"][mode])
	$VBox/DiffLabel.text = tr(Difficulty.label_key(difficulty))


func _refresh_scores() -> void:
	var top := SaveService.get_top5(mode, difficulty)
	var lines: PackedStringArray = [tr("score")]
	var sum_pts := 0
	for s in top:
		sum_pts += int(s.points)
		if mode == 1:
			lines.append("%s  %.1fs" % [s.name, float(s.time)])
		else:
			lines.append("%s  %d" % [s.name, int(s.points)])
	if top.size() > 0:
		lines.append("%s %d" % [tr("average_score"), int(float(sum_pts) / float(top.size()))])
	$VBox/Scores.text = "\n".join(lines)


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
