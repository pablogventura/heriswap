extends Control


func _ready() -> void:
	var pages := [
		_strip_icons(tr("help_general_1")),
		_strip_icons(tr("help_general_2")),
		_strip_icons(tr("help_mode1_1")),
		_strip_icons(tr("help_mode1_2")),
		_strip_icons(tr("help_mode2_1")),
		_strip_icons(tr("help_mode2_2")),
		_strip_icons(tr("help_mode3_1")),
	]
	$VBox/Text.text = "\n\n".join(pages)
	$VBox/Back.pressed.connect(func():
		if GameFlow.returning_from_match:
			GameFlow.go_match()
		else:
			GameFlow.go_mode_menu()
	)


func _strip_icons(s: String) -> String:
	# Remove sac markup ×tex,scale×
	var re := RegEx.new()
	re.compile("×[^×]+×")
	return re.sub(s, "", true)
