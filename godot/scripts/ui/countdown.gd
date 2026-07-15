extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_label($Label, 96)
	var curtain := ColorRect.new()
	curtain.name = "Curtain"
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color(0, 0, 0, 0.55)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(curtain)
	move_child(curtain, 0)
	$Label.text = "3"
	var tw := create_tween()
	tw.tween_property(curtain, "color:a", 0.2, 0.55)
	await get_tree().create_timer(0.6).timeout
	$Label.text = "2"
	await get_tree().create_timer(0.6).timeout
	$Label.text = "1"
	await get_tree().create_timer(0.5).timeout
	tw = create_tween()
	tw.tween_property(curtain, "color:a", 1.0, 0.25)
	await tw.finished
	GameFlow.go_match()
