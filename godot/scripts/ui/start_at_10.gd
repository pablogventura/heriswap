extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_button($Yes)
	UiTheme.style_button($No)
	UiTheme.style_label($Text, 28)
	$Text.text = tr("start_at_level_10")
	$Yes.text = tr("start_at_level_10_yes")
	$No.text = tr("play")
	$Yes.pressed.connect(func():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 10)
	)
	$No.pressed.connect(func():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	)
