extends Control

var _pages: PackedStringArray = []
var _index: int = 0


func _ready() -> void:
	_pages = PackedStringArray([
		_to_bbcode(tr("help_general_1")),
		_to_bbcode(tr("help_general_2")),
		_to_bbcode(tr("help_mode1_1")),
		_to_bbcode(tr("help_mode1_2")),
		_to_bbcode(tr("help_mode2_1")),
		_to_bbcode(tr("help_mode2_2")),
		_to_bbcode(tr("help_mode3_1")),
	])
	_show_page()
	if not $VBox.has_node("Next"):
		var next := Button.new()
		next.name = "Next"
		next.text = tr("help_click_continue")
		$VBox.add_child(next)
		$VBox.move_child(next, 1)
	$VBox/Next.pressed.connect(_next)
	$VBox/Back.text = tr("give_up") if false else "Back"
	$VBox/Back.pressed.connect(_back)


func _to_bbcode(s: String) -> String:
	# Convert ×feuille1,1× style into plain emphasis; keep readability.
	var re := RegEx.new()
	re.compile("×([^,×]+),[^×]+×")
	return re.sub(s, "[img]res://assets/textures/feuilles/$1.png[/img]", true)


func _show_page() -> void:
	$VBox/Text.bbcode_enabled = true
	$VBox/Text.text = _pages[_index]
	$VBox/Next.text = tr("help_click_play") if _index >= _pages.size() - 1 else tr("help_click_continue")


func _next() -> void:
	if _index >= _pages.size() - 1:
		_finish()
		return
	_index += 1
	_show_page()


func _back() -> void:
	if GameFlow.returning_from_match:
		GameFlow.go_match()
	else:
		GameFlow.go_mode_menu()


func _finish() -> void:
	if GameFlow.returning_from_match:
		GameFlow.go_match()
	elif SaveService.get_top5(GameFlow.selected_mode, GameFlow.selected_difficulty).is_empty():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	else:
		GameFlow.go_mode_menu()
