extends Control

var _pages: Array = [] ## {text, icons}
var _index: int = 0
var _next_btn: Button
var _text: RichTextLabel
var _icons: HBoxContainer


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	_pages = [
		{"text": _plain(tr("help_general_1")), "icons": ["feuille1", "feuille2", "feuille3"]},
		{"text": _plain(tr("help_general_2")), "icons": ["herisson_2_5"]},
		{"text": _plain(tr("help_mode1_1")), "icons": ["feuille5"]},
		{"text": _plain(tr("help_mode1_2")), "icons": ["feuille5"]},
		{"text": _plain(tr("help_mode2_1")), "icons": ["feuille1", "feuille2"]},
		{"text": _plain(tr("help_mode2_2")), "icons": ["feuille5"]},
		{"text": _plain(tr("help_mode3_1")), "icons": ["feuille1"]},
	]
	_text = $VBox/Text
	_text.bbcode_enabled = false
	_icons = $VBox.get_node_or_null("Icons") as HBoxContainer
	if _icons == null:
		_icons = HBoxContainer.new()
		_icons.name = "Icons"
		_icons.alignment = BoxContainer.ALIGNMENT_CENTER
		$VBox.add_child(_icons)
		$VBox.move_child(_icons, 0)
	_next_btn = $VBox.get_node_or_null("Next") as Button
	if _next_btn == null:
		_next_btn = Button.new()
		_next_btn.name = "Next"
		$VBox.add_child(_next_btn)
		$VBox.move_child(_next_btn, 2)
	UiTheme.style_button(_next_btn)
	UiTheme.style_button($VBox/Back)
	if not _next_btn.pressed.is_connected(_next):
		_next_btn.pressed.connect(_next)
	$VBox/Back.text = tr("quit")
	if not $VBox/Back.pressed.is_connected(_back):
		$VBox/Back.pressed.connect(_back)
	_show_page()


func _plain(s: String) -> String:
	var re := RegEx.new()
	re.compile("×[^×]+×")
	return re.sub(s, "", true)


func _show_page() -> void:
	if _text == null or _next_btn == null:
		return
	var page: Dictionary = _pages[_index]
	_text.text = str(page.text)
	for c in _icons.get_children():
		c.queue_free()
	for name in page.icons:
		var path := "res://assets/textures/feuilles/%s.png" % name
		if not ResourceLoader.exists(path):
			continue
		var tr := TextureRect.new()
		tr.texture = load(path)
		tr.custom_minimum_size = Vector2(64, 64)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icons.add_child(tr)
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
	GameFlow.returning_from_match = false
	if SaveService.get_top5(GameFlow.selected_mode, GameFlow.selected_difficulty).is_empty():
		GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, 1)
	else:
		GameFlow.go_mode_menu()
