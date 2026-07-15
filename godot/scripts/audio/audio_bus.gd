extends Node

## Multi-track jukebox + stress ADSR-like ramp.

var _menu: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _master: AudioStreamPlayer
var _secondary: Array = []
var _stress: AudioStreamPlayer
var _stress_target: float = 0.0
var _stress_value: float = 0.0


func _ready() -> void:
	_menu = AudioStreamPlayer.new()
	_sfx = AudioStreamPlayer.new()
	_master = AudioStreamPlayer.new()
	_stress = AudioStreamPlayer.new()
	add_child(_menu)
	add_child(_sfx)
	add_child(_master)
	add_child(_stress)
	for track in ["B.ogg", "C.ogg", "D.ogg", "E.ogg", "G.ogg", "I.ogg"]:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_secondary.append({"player": p, "file": track})
	apply_mute(not SaveService.is_sound_on())


func _process(dt: float) -> void:
	_stress_value = move_toward(_stress_value, _stress_target, dt * 0.5)
	if _stress_value <= 0.01:
		if _stress.playing:
			_stress.stop()
	else:
		if not _stress.playing:
			_play_loop(_stress, "res://assets/audio/F.ogg")
		_stress.volume_db = linear_to_db(_stress_value)


func apply_mute(muted: bool) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, muted)


func play_menu_music() -> void:
	stop_all_music()
	_play_loop(_menu, "res://assets/audio/musique_menu.ogg")


func stop_menu_music() -> void:
	_menu.stop()


func play_sfx(path: String) -> void:
	if not SaveService.is_sound_on():
		return
	var stream := load(path)
	if stream:
		_sfx.stream = stream
		_sfx.pitch_scale = 1.0
		_sfx.play()


func play_level_up() -> void:
	play_sfx("res://assets/audio/level_up.ogg")


func play_swap() -> void:
	play_sfx("res://assets/audio/son_monte.ogg")


func play_match() -> void:
	play_sfx("res://assets/audio/son_descend.ogg")


func play_match_combo(chain: int) -> void:
	if not SaveService.is_sound_on():
		return
	var stream := load("res://assets/audio/son_descend.ogg")
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.pitch_scale = 1.0 + 0.08 * float(mini(chain, 6))
	_sfx.play()


func play_invalid_swap() -> void:
	if not SaveService.is_sound_on():
		return
	var stream := load("res://assets/audio/son_monte.ogg")
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.pitch_scale = 0.72
	_sfx.play()


func play_land() -> void:
	if not SaveService.is_sound_on():
		return
	var stream := load("res://assets/audio/son_descend.ogg")
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.pitch_scale = 1.25
	_sfx.play()


func play_spawn_pop() -> void:
	if not SaveService.is_sound_on():
		return
	var stream := load("res://assets/audio/son_menu.ogg")
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.pitch_scale = 1.35
	_sfx.play()


func play_click() -> void:
	_sfx.pitch_scale = 1.0
	play_sfx("res://assets/audio/son_menu.ogg")


func start_game_music() -> void:
	stop_menu_music()
	_play_loop(_master, "res://assets/audio/A.ogg")
	for i in _secondary.size():
		var entry: Dictionary = _secondary[i]
		var p: AudioStreamPlayer = entry.player
		_play_loop(p, "res://assets/audio/%s" % entry.file)
		p.volume_db = linear_to_db(0.35 + 0.08 * float(i))


func set_stress(amount: float) -> void:
	_stress_target = clampf(amount, 0.0, 1.0)


func stop_all_music() -> void:
	_menu.stop()
	_master.stop()
	_stress.stop()
	_stress_target = 0.0
	_stress_value = 0.0
	for entry in _secondary:
		entry.player.stop()


func _play_loop(player: AudioStreamPlayer, path: String) -> void:
	var stream := load(path)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	player.stream = stream
	if not player.playing:
		player.play()
