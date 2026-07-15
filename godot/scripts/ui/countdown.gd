extends Control


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_label($Label, 120)
	$Label.set_anchors_preset(Control.PRESET_CENTER)
	$Label.offset_left = -200
	$Label.offset_right = 200
	$Label.offset_top = -80
	$Label.offset_bottom = 80
	var curtain := ColorRect.new()
	curtain.name = "Curtain"
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color(0, 0, 0, 0.0)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(curtain)
	move_child(curtain, 0)
	# Vorhang-like: curtain drops, count, then full close.
	var tw := create_tween()
	tw.tween_property(curtain, "color:a", 0.65, 0.35)
	await tw.finished
	for n in ["3", "2", "1"]:
		$Label.text = n
		$Label.modulate = Color(1, 1, 1, 0)
		$Label.scale = Vector2(1.4, 1.4)
		var pulse := create_tween()
		pulse.tween_property($Label, "modulate:a", 1.0, 0.15)
		pulse.parallel().tween_property($Label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.55).timeout
	tw = create_tween()
	tw.tween_property(curtain, "color:a", 1.0, 0.28)
	await tw.finished
	GameFlow.go_match()
