extends Control

var mode: int = 0
var difficulty: int = Difficulty.EASY


func _ready() -> void:
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
	var lines: PackedStringArray = [tr("score")]
	for s in SaveService.get_top5(mode, difficulty):
		if mode == 1:
			lines.append("%s  %.1fs" % [s.name, float(s.time)])
		else:
			lines.append("%s  %d" % [s.name, int(s.points)])
	$VBox/Scores.text = "\n".join(lines)


func _play() -> void:
	AudioBus.play_click()
	# Offer start at 10 for Normal + good history (simplified: game_count > 5)
	if mode == 0 and int(SaveService.options.get("game_count", 0)) > 5:
		GameFlow.selected_mode = mode
		GameFlow.selected_difficulty = difficulty
		GameFlow.go_start_at_10()
	else:
		GameFlow.begin_run(mode, difficulty, 1)
