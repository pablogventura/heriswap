extends Node

## Loads CSV translations at runtime (no import step required for CI/headless).

const CSV_PATH := "res://localization/heriswap.csv"
var _loaded: bool = false


func _ready() -> void:
	_ensure_translations()
	var loc := str(SaveService.options.get("locale", "en"))
	TranslationServer.set_locale(loc)


func _ensure_translations() -> void:
	if _loaded:
		return
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	if f == null:
		push_warning("LocaleService: missing CSV")
		return
	var header := f.get_csv_line()
	if header.size() < 2:
		return
	var locales: Array = []
	for i in range(1, header.size()):
		var trn := Translation.new()
		trn.locale = header[i]
		locales.append(trn)
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2:
			continue
		var key := row[0]
		if key == "" or key == "keys":
			continue
		for i in range(1, mini(row.size(), header.size())):
			(locales[i - 1] as Translation).add_message(key, row[i])
	for trn in locales:
		TranslationServer.add_translation(trn)
	_loaded = true


func set_locale(code: String) -> void:
	_ensure_translations()
	SaveService.options["locale"] = code
	SaveService.save_options()
	TranslationServer.set_locale(code)


func tr_key(key: String) -> String:
	return tr(key)
