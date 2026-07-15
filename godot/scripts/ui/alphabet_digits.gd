class_name AlphabetDigits
extends HBoxContainer

## Renders numeric / score strings with original alphabet bitmap glyphs.
## Falls back to a FreeMono Label when a glyph is missing.

const GLYPH_DIR := "res://assets/textures/alphabet/"
const DIGIT_H := 36.0

var _cache: Dictionary = {}
var _fallback: Label
var glyph_height: float = DIGIT_H


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_display(text: String) -> void:
	for c in get_children():
		if c != _fallback:
			c.queue_free()
	if _fallback and is_instance_valid(_fallback):
		_fallback.visible = false
	var missing := false
	for ch in text:
		var code := ch.unicode_at(0)
		var hex := "%x" % code
		var path := "%s%s_typo.png" % [GLYPH_DIR, hex]
		if not ResourceLoader.exists(path):
			missing = true
			break
		var tr := TextureRect.new()
		tr.texture = _tex(path)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(glyph_height * 0.7, glyph_height)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
	if missing:
		_clear_glyphs()
		_ensure_fallback()
		_fallback.text = text
		_fallback.visible = true


func _clear_glyphs() -> void:
	for c in get_children():
		if c != _fallback:
			c.queue_free()


func _ensure_fallback() -> void:
	if _fallback != null and is_instance_valid(_fallback):
		return
	_fallback = Label.new()
	_fallback.name = "Fallback"
	UiTheme.style_label(_fallback, int(glyph_height))
	_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_fallback)


func _tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = load(path)
	_cache[path] = t
	return t
