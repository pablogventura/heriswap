extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_buttons_in($VBox)
	$VBox/Text.text = tr("start_at_level_10")
	$VBox/Yes.text = tr("start_at_level_10_yes")
	$VBox/No.text = tr("play")
	$VBox/Yes.pressed.connect(func():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 10)
	)
	$VBox/No.pressed.connect(func():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	)
