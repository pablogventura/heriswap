extends Control


func _ready() -> void:
	$VBox/Text.text = tr("change_difficulty")
	$VBox/Yes.text = tr("change_difficulty_yes")
	$VBox/No.text = tr("change_difficulty_no")
	$VBox/Yes.pressed.connect(func():
		GameFlow.selected_difficulty = Difficulty.next(GameFlow.selected_difficulty)
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	)
	$VBox/No.pressed.connect(func():
		# Continue current run after level 10 celebration.
		GameFlow.go_match()
	)
