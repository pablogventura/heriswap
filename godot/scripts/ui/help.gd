extends Control

var _pages: Array = [] ## {text, icons, bg}
var _index: int = 0


func _ready() -> void:
	UiTheme.apply_backdrop(self)
	UiTheme.style_button($Next)
	UiTheme.style_button($Back)
	_pages = [
		{"text": _plain(tr("help_general_1")), "icons": ["feuille1", "feuille2", "feuille3"], "bg": "bg_help_howto"},
		{"text": _plain(tr("help_general_2")), "icons": ["herisson_2_5"], "bg": "bg_help_howto"},
		{"text": _plain(tr("help_mode1_1")), "icons": ["feuille5"], "bg": "bg_help_obj_score"},
		{"text": _plain(tr("help_mode1_2")), "icons": ["feuille5"], "bg": "bg_help_obj_score"},
		{"text": _plain(tr("help_mode2_1")), "icons": ["feuille1", "feuille2"], "bg": "bg_help_obj_time"},
		{"text": _plain(tr("help_mode2_2")), "icons": ["feuille5"], "bg": "bg_help_obj_time"},
		{"text": _plain(tr("help_mode3_1")), "icons": ["feuille1"], "bg": "bg_help_howto"},
	]
	$Text.add_theme_font_override("normal_font", UiTheme.font())
	$Text.add_theme_font_size_override("normal_font_size", 26)
	$Back.text = tr("quit")
	if not $Next.pressed.is_connected(_next):
		$Next.pressed.connect(_next)
	if not $Back.pressed.is_connected(_back):
		$Back.pressed.connect(_back)
	_show_page()


func _plain(s: String) -> String:
	var re := RegEx.new()
	re.compile("×[^×]+×")
	return re.sub(s, "", true)


func _show_page() -> void:
	var page: Dictionary = _pages[_index]
	$Text.text = str(page.text)
	var bg_path := "res://assets/textures/help/%s.png" % str(page.get("bg", "bg_help_howto"))
	if ResourceLoader.exists(bg_path):
		$HelpBg.texture = load(bg_path)
		$HelpBg.modulate = Color(1, 1, 1, 0.55)
	for c in $Icons.get_children():
		c.queue_free()
	for name in page.icons:
		var path := "res://assets/textures/feuilles/%s.png" % name
		if not ResourceLoader.exists(path):
			continue
		var tr := TextureRect.new()
		tr.texture = load(path)
		tr.custom_minimum_size = Vector2(72, 72)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		$Icons.add_child(tr)
	$Next.text = tr("help_click_play") if _index >= _pages.size() - 1 else tr("help_click_continue")


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
