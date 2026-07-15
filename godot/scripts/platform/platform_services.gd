extends Node

## Offline-first platform bridge. No Play/Billing plugins in this build.

signal achievement_unlocked(id: String)
signal purchase_finished(product_id: String, success: bool)

var _play_enabled: bool = false
var _iap_enabled: bool = false


func _ready() -> void:
	_refresh_flags()


func _refresh_flags() -> void:
	# Explicitly offline: never enable proprietary services in this product pass.
	_play_enabled = false
	_iap_enabled = false


func is_fdroid() -> bool:
	return OS.has_feature("fdroid") or not OS.has_feature("android")


func vibrate(ms: int = 30) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func open_url(url: String) -> void:
	OS.shell_open(url)


func unlock_achievement(achievement_id: String) -> void:
	achievement_unlocked.emit(achievement_id)


func submit_score(_leaderboard_id: String, _score: int) -> void:
	pass


func purchase_donate() -> void:
	purchase_finished.emit("donate", false)
	open_url("https://flattr.com/")


func show_rate_store() -> void:
	# Offline / F-Droid: no Play Store rating.
	pass


func can_show_rate() -> bool:
	return false


func can_show_leaderboard() -> bool:
	return false


func is_play_enabled() -> bool:
	return false


func is_iap_enabled() -> bool:
	return false


func application_id() -> String:
	return "net.damsy.soupeaucaillou.heriswap2"
