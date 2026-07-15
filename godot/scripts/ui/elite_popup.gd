extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_button($Yes)
	UiTheme.style_button($No)
	UiTheme.style_label($Text, 28)
	$Text.text = tr("change_difficulty")
	$Yes.text = tr("change_difficulty_yes")
	$No.text = tr("change_difficulty_no")
	$Yes.pressed.connect(func():
		GameFlow.selected_difficulty = Difficulty.next(GameFlow.selected_difficulty)
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	)
	$No.pressed.connect(func():
		GameFlow.go_match()
	)
