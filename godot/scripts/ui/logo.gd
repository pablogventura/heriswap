extends Control


func _ready() -> void:
	$Center/Title.text = "Heriswap"
	$Center/Subtitle.text = "Godot rewrite"
	await get_tree().create_timer(1.4).timeout
	GameFlow.go_main_menu()
