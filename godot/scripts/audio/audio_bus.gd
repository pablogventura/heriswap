extends Node

var _menu: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _music: AudioStreamPlayer
var _stress: AudioStreamPlayer


func _ready() -> void:
	_menu = AudioStreamPlayer.new()
	_sfx = AudioStreamPlayer.new()
	_music = AudioStreamPlayer.new()
	_stress = AudioStreamPlayer.new()
	add_child(_menu)
	add_child(_sfx)
	add_child(_music)
	add_child(_stress)
	apply_mute(not SaveService.is_sound_on())


func apply_mute(muted: bool) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, muted)


func play_menu_music() -> void:
	_play_loop(_menu, "res://assets/audio/musique_menu.ogg")


func stop_menu_music() -> void:
	_menu.stop()


func play_sfx(path: String) -> void:
	if not SaveService.is_sound_on():
		return
	var stream := load(path)
	if stream:
		_sfx.stream = stream
		_sfx.play()


func play_level_up() -> void:
	play_sfx("res://assets/audio/level_up.ogg")


func play_swap() -> void:
	play_sfx("res://assets/audio/son_monte.ogg")


func play_match() -> void:
	play_sfx("res://assets/audio/son_descend.ogg")


func play_click() -> void:
	play_sfx("res://assets/audio/son_menu.ogg")


func start_game_music() -> void:
	_play_loop(_music, "res://assets/audio/A.ogg")


func set_stress(amount: float) -> void:
	if amount <= 0.01:
		_stress.stop()
		return
	if not _stress.playing:
		_play_loop(_stress, "res://assets/audio/F.ogg")
	_stress.volume_db = linear_to_db(clampf(amount, 0.0, 1.0))


func stop_all_music() -> void:
	_menu.stop()
	_music.stop()
	_stress.stop()


func _play_loop(player: AudioStreamPlayer, path: String) -> void:
	var stream := load(path)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	player.stream = stream
	if not player.playing:
		player.play()
