extends Control


func _ready() -> void:
	$VBox/Text.text = tr("change_difficulty")
	$VBox/Yes.pressed.connect(func():
		GameFlow.selected_difficulty = Difficulty.next(GameFlow.selected_difficulty)
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	)
	$VBox/No.pressed.connect(func(): GameFlow.go_mode_menu())
