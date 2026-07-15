extends Control


func _ready() -> void:
	$Label.text = "3"
	await get_tree().create_timer(0.6).timeout
	$Label.text = "2"
	await get_tree().create_timer(0.6).timeout
	$Label.text = "1"
	await get_tree().create_timer(0.6).timeout
	GameFlow.go_match()
