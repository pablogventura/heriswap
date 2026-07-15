extends Node

## Offline-first platform bridge. Real Google Play / IAP plug in here later.

signal achievement_unlocked(id: String)
signal purchase_finished(product_id: String, success: bool)

var _play_enabled: bool = false
var _iap_enabled: bool = false


func _ready() -> void:
	# Feature flags: never require Google for gameplay.
	_play_enabled = false
	_iap_enabled = false
	if OS.has_feature("android") and OS.get_environment("HERISWAP_ENABLE_PLAY") == "1":
		_play_enabled = true
		_iap_enabled = true


func vibrate(ms: int = 30) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func open_url(url: String) -> void:
	OS.shell_open(url)


func unlock_achievement(achievement_id: String) -> void:
	achievement_unlocked.emit(achievement_id)
	if _play_enabled:
		# Hook for Play Games plugin.
		pass


func submit_score(leaderboard_id: String, score: int) -> void:
	if _play_enabled:
		pass
	else:
		push_warning("PlatformServices: leaderboard stub %s=%d" % [leaderboard_id, score])


func purchase_donate() -> void:
	if not _iap_enabled:
		purchase_finished.emit("donate", false)
		open_url("https://flattr.com/")
		return
	# Hook for billing plugin.
	purchase_finished.emit("donate", false)


func show_rate_dialog() -> void:
	# Handled by RateIt scene in-game.
	pass


func is_play_enabled() -> bool:
	return _play_enabled


func is_iap_enabled() -> bool:
	return _iap_enabled


func application_id() -> String:
	return "net.damsy.soupeaucaillou.heriswap2"
