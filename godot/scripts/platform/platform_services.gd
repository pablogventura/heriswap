extends Node

## Offline-first platform bridge.

signal achievement_unlocked(id: String)
signal purchase_finished(product_id: String, success: bool)

var _play_enabled: bool = false
var _iap_enabled: bool = false


func _ready() -> void:
	_refresh_flags()


func _refresh_flags() -> void:
	var fdroid := OS.has_feature("fdroid")
	var android := OS.has_feature("android")
	_play_enabled = android and not fdroid and (
		OS.get_environment("HERISWAP_ENABLE_PLAY") == "1" or OS.has_feature("play")
	)
	_iap_enabled = _play_enabled
	# Native plugin hook if present.
	if Engine.has_singleton("GodotPlayGamesServices"):
		_play_enabled = android and not fdroid
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_iap_enabled = android and not fdroid


func is_fdroid() -> bool:
	return OS.has_feature("fdroid")


func vibrate(ms: int = 30) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func open_url(url: String) -> void:
	OS.shell_open(url)


func unlock_achievement(achievement_id: String) -> void:
	achievement_unlocked.emit(achievement_id)
	if not _play_enabled:
		return
	if Engine.has_singleton("GodotPlayGamesServices"):
		# Plugin-specific call would go here.
		pass


func submit_score(leaderboard_id: String, score: int) -> void:
	if not _play_enabled:
		return
	push_warning("PlatformServices: leaderboard %s=%d" % [leaderboard_id, score])


func purchase_donate() -> void:
	if is_fdroid() or not _iap_enabled:
		purchase_finished.emit("donate", false)
		open_url("https://flattr.com/")
		return
	if Engine.has_singleton("GodotGooglePlayBilling"):
		purchase_finished.emit("donate", false)
		return
	purchase_finished.emit("donate", false)
	open_url("https://play.google.com/store/apps/details?id=%s" % application_id())


func show_rate_store() -> void:
	if is_fdroid():
		return
	open_url("https://play.google.com/store/apps/details?id=%s" % application_id())


func can_show_rate() -> bool:
	return not is_fdroid()


func can_show_leaderboard() -> bool:
	return _play_enabled


func is_play_enabled() -> bool:
	return _play_enabled


func is_iap_enabled() -> bool:
	return _iap_enabled


func application_id() -> String:
	return "net.damsy.soupeaucaillou.heriswap2"
