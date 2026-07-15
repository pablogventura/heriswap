extends Control

var _pages: PackedStringArray = []
var _index: int = 0
var _next_btn: Button
var _text: RichTextLabel


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
	_text = $VBox/Text
	_text.bbcode_enabled = true
	_next_btn = $VBox.get_node_or_null("Next") as Button
	if _next_btn == null:
		_next_btn = Button.new()
		_next_btn.name = "Next"
		$VBox.add_child(_next_btn)
		$VBox.move_child(_next_btn, 1)
	if not _next_btn.pressed.is_connected(_next):
		_next_btn.pressed.connect(_next)
	$VBox/Back.text = "Back"
	if not $VBox/Back.pressed.is_connected(_back):
		$VBox/Back.pressed.connect(_back)
	_show_page()


func _to_bbcode(s: String) -> String:
	var re := RegEx.new()
	re.compile("×([^,×]+),[^×]+×")
	return re.sub(s, "[img]res://assets/textures/feuilles/$1.png[/img]", true)


func _show_page() -> void:
	if _text == null or _next_btn == null:
		return
	_text.text = _pages[_index]
	_next_btn.text = tr("help_click_play") if _index >= _pages.size() - 1 else tr("help_click_continue")


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
