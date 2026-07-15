extends Control


func _ready() -> void:
	$VBox/Text.text = tr("start_at_level_10")
	$VBox/Yes.pressed.connect(func():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 10)
	)
	$VBox/No.pressed.connect(func():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	)
