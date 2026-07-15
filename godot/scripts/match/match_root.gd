extends Control

## Match loop: UserInput → Delete → Fall → Spawn (+ LevelChanged / EndGame).

enum Phase { USER_INPUT, DELETE, FALL, SPAWN, LEVEL_CHANGED, PAUSED, GAME_OVER }

var grid: GridModel
var mode: GameModeBase
var phase: int = Phase.USER_INPUT
var cell_size: float = 64.0
var grid_origin: Vector2 = Vector2.ZERO
var leaf_textures: Array = []
var sprites: Dictionary = {} ## Vector2i -> Sprite2D

var drag_start: Vector2i = Vector2i(-1, -1)
var input_enabled: bool = true
var phase_timer: float = 0.0
var pending_combos: Array = []
var restore_paused: bool = false

@onready var grid_layer: Node2D = $GridLayer
@onready var hud_label: Label = $HUD/ScoreLabel
@onready var progress_bar: ProgressBar = $HUD/ProgressBar
@onready var pause_panel: Panel = $PausePanel
@onready var hint_btn: Button = $HUD/HintButton
@onready var pause_btn: Button = $HUD/PauseButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_textures()
	grid = GridModel.new()
	var diff: int = GameFlow.selected_difficulty
	grid.set_difficulty(diff)
	mode = GameModeBase.create(GameFlow.selected_mode)
	mode.enter(diff, GameFlow.start_level)

	var snapshot := RunSnapshot.load_run()
	if not snapshot.is_empty() and int(snapshot.get("mode", -1)) == GameFlow.selected_mode:
		_restore(snapshot)
		restore_paused = true
	else:
		grid.fill_until_playable()
		phase = Phase.SPAWN
		phase_timer = 0.15

	await get_tree().process_frame
	_layout_grid()
	_rebuild_sprites()
	AudioBus.stop_menu_music()
	AudioBus.start_game_music()
	SaveService.bump_game_count()
	pause_panel.visible = false
	pause_btn.pressed.connect(_toggle_pause)
	hint_btn.pressed.connect(_on_hint)
	$PausePanel/VBox/Resume.pressed.connect(_toggle_pause)
	$PausePanel/VBox/Help.pressed.connect(func(): GameFlow.go_help())
	$PausePanel/VBox/Quit.pressed.connect(_abort_to_menu)
	if restore_paused:
		_toggle_pause()


func _load_textures() -> void:
	leaf_textures.clear()
	for i in range(1, 9):
		leaf_textures.append(load("res://assets/textures/feuilles/feuille%d.png" % i))


func _layout_grid() -> void:
	var rect := get_viewport_rect().size
	if size.x > 1.0:
		rect = size
	var margin := 40.0
	var avail_w := rect.x - margin * 2.0
	var avail_h := rect.y * 0.55
	cell_size = mini(avail_w / float(grid.grid_size), avail_h / float(grid.grid_size))
	var total := cell_size * float(grid.grid_size)
	grid_origin = Vector2((rect.x - total) * 0.5, rect.y * 0.28)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_grid()
		_rebuild_sprites()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		if phase != Phase.GAME_OVER and phase != Phase.PAUSED:
			_save_snapshot()
			if phase != Phase.PAUSED:
				_toggle_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_pause()


func _process(dt: float) -> void:
	if phase == Phase.PAUSED or phase == Phase.GAME_OVER:
		return
	mode.update(dt, grid)
	Achievements.tick(dt)
	if mode is NormalMode:
		AudioBus.set_stress((mode as NormalMode).stress_amount())
	_update_hud()
	if mode.finished:
		_on_mode_finished_achievements()
		_end_game()
		return
	match phase:
		Phase.DELETE:
			phase_timer -= dt
			if phase_timer <= 0.0:
				_finish_delete()
		Phase.FALL:
			phase_timer -= dt
			if phase_timer <= 0.0:
				_finish_fall()
		Phase.SPAWN:
			phase_timer -= dt
			if phase_timer <= 0.0:
				_finish_spawn()
		Phase.LEVEL_CHANGED:
			phase_timer -= dt
			if phase_timer <= 0.0:
				phase = Phase.SPAWN
				phase_timer = 0.2
				_rebuild_sprites()
		Phase.USER_INPUT:
			pass


func _update_hud() -> void:
	hud_label.text = mode.hud_text()
	progress_bar.value = mode.progress() * 100.0


func _rebuild_sprites() -> void:
	for s in sprites.values():
		if is_instance_valid(s):
			s.queue_free()
	sprites.clear()
	for x in grid.grid_size:
		for y in grid.grid_size:
			var t: int = grid.get_cell(x, y)
			if t < 0:
				continue
			_make_sprite(Vector2i(x, y), t)


func _make_sprite(pos: Vector2i, leaf_type: int) -> void:
	var spr := Sprite2D.new()
	spr.texture = leaf_textures[clampi(leaf_type, 0, leaf_textures.size() - 1)]
	spr.centered = true
	var tex_size: Vector2 = spr.texture.get_size()
	spr.scale = Vector2.ONE * (cell_size * 0.9 / maxf(tex_size.x, tex_size.y))
	spr.position = _cell_to_screen(pos)
	grid_layer.add_child(spr)
	sprites[pos] = spr


func _cell_to_screen(pos: Vector2i) -> Vector2:
	# y=0 bottom visually near bottom of grid area → invert for screen
	var screen_y := float(grid.grid_size - 1 - pos.y)
	return grid_origin + Vector2((float(pos.x) + 0.5) * cell_size, (screen_y + 0.5) * cell_size)


func _screen_to_cell(screen: Vector2) -> Vector2i:
	var local := screen - grid_origin
	var x := int(local.x / cell_size)
	var screen_y := int(local.y / cell_size)
	var y := grid.grid_size - 1 - screen_y
	return Vector2i(x, y)


func _gui_input(event: InputEvent) -> void:
	if phase != Phase.USER_INPUT or not input_enabled:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			drag_start = _screen_to_cell(st.position)
		else:
			_try_swap(drag_start, _screen_to_cell(st.position))
			drag_start = Vector2i(-1, -1)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			drag_start = _screen_to_cell(mb.position)
		else:
			_try_swap(drag_start, _screen_to_cell(mb.position))
			drag_start = Vector2i(-1, -1)


func _try_swap(a: Vector2i, b: Vector2i) -> void:
	if not grid.is_valid(a.x, a.y) or not grid.is_valid(b.x, b.y):
		return
	if abs(a.x - b.x) + abs(a.y - b.y) != 1:
		return
	if grid.get_cell(a.x, a.y) < 0 or grid.get_cell(b.x, b.y) < 0:
		return
	if not grid.would_swap_match(a, b):
		PlatformServices.vibrate(15)
		return
	grid.swap_cells(a, b)
	AudioBus.play_swap()
	_rebuild_sprites()
	_begin_delete()


func _begin_delete() -> void:
	pending_combos = grid.look_for_combinations()
	if pending_combos.is_empty():
		phase = Phase.USER_INPUT
		return
	phase = Phase.DELETE
	phase_timer = 0.35
	AudioBus.play_match()
	# Pulse matched sprites
	for combo in pending_combos:
		for p in combo.points:
			if sprites.has(p):
				var tw := create_tween()
				tw.tween_property(sprites[p], "scale", sprites[p].scale * 0.2, 0.3)


func _finish_delete() -> void:
	var all_points: Array = []
	for combo in pending_combos:
		mode.score_calc(combo.points.size(), combo.type, grid)
		_notify_achievements(mode.last_score_event)
		all_points.append_array(combo.points)
	grid.remove_points(all_points)
	_rebuild_sprites()
	phase = Phase.FALL
	phase_timer = 0.25


func _finish_fall() -> void:
	var falls := grid.tile_fall()
	while not falls.is_empty():
		grid.apply_falls(falls)
		falls = grid.tile_fall()
	_rebuild_sprites()
	if not grid.look_for_combinations().is_empty():
		_begin_delete()
		return
	phase = Phase.SPAWN
	phase_timer = 0.2


func _finish_spawn() -> void:
	if not grid.still_combinations():
		Achievements.mark_grid_reset()
		grid.fill_until_playable()
	else:
		grid.fill_blanks()
		# Keep filling until no immediate combos if possible
		var guard := 0
		while not grid.look_for_combinations().is_empty() and guard < 20:
			for combo in grid.look_for_combinations():
				grid.remove_points(combo.points)
			var falls := grid.tile_fall()
			while not falls.is_empty():
				grid.apply_falls(falls)
				falls = grid.tile_fall()
			grid.fill_blanks()
			guard += 1
	_rebuild_sprites()
	if mode.is_level_up():
		var prev_level := mode.level
		var prev_points := mode.points
		mode.on_level_up(grid)
		Achievements.s_level1_for_2k(prev_level, prev_points)
		Achievements.s_level10(mode.level)
		AudioBus.play_level_up()
		phase = Phase.LEVEL_CHANGED
		phase_timer = 0.8
		return
	if mode.finished:
		_on_mode_finished_achievements()
		_end_game()
		return
	phase = Phase.USER_INPUT
	_save_snapshot()


func _on_hint() -> void:
	if mode is NormalMode and not (mode as NormalMode).help_available:
		return
	var hint: Array = grid.find_hint()
	if hint.size() < 2:
		return
	for p in hint:
		if sprites.has(p):
			var tw := create_tween()
			tw.tween_property(sprites[p], "modulate", Color(2, 2, 1), 0.2)
			tw.tween_property(sprites[p], "modulate", Color.WHITE, 0.2)


func _toggle_pause() -> void:
	if phase == Phase.GAME_OVER:
		return
	if phase == Phase.PAUSED:
		phase = Phase.USER_INPUT
		pause_panel.visible = false
		_save_snapshot()
	else:
		phase = Phase.PAUSED
		pause_panel.visible = true
		_save_snapshot()


func _abort_to_menu() -> void:
	RunSnapshot.clear()
	AudioBus.stop_all_music()
	GameFlow.returning_from_match = true
	GameFlow.go_mode_menu()


func _notify_achievements(ev: Dictionary) -> void:
	if ev.is_empty():
		return
	Achievements.s6_in_a_row(int(ev.get("nb", 0)))
	Achievements.s_rainbow(int(ev.get("type", -1)))
	Achievements.s_bonus_to_excess(int(ev.get("type", -1)), int(ev.get("bonus", -2)), int(ev.get("nb", 0)))
	Achievements.s_extermina_score(int(ev.get("points", 0)))


func _on_mode_finished_achievements() -> void:
	if mode.mode_id() == GameModeBase.MODE_TILES_ATTACK and mode.won:
		Achievements.s_fast_and_finish(mode.time_sec)
		Achievements.s_reset_grid()
	Achievements.s_take_your_time()


func _end_game() -> void:
	phase = Phase.GAME_OVER
	RunSnapshot.clear()
	AudioBus.stop_all_music()
	GameFlow.last_score = {
		"points": mode.points,
		"level": mode.level,
		"time": mode.time_sec,
		"mode": mode.mode_id(),
		"difficulty": GameFlow.selected_difficulty,
		"won": mode.won,
	}
	Achievements.s_hard_score_total(_total_points_all_time())
	GameFlow.go_end_game()


func _total_points_all_time() -> int:
	var total := mode.points
	for s in SaveService.load_scores():
		total += int(s.get("points", 0))
	return total


func _save_snapshot() -> void:
	if phase == Phase.GAME_OVER:
		return
	RunSnapshot.save_run({
		"mode": mode.mode_id(),
		"difficulty": GameFlow.selected_difficulty,
		"phase": phase,
		"grid": grid.to_dict(),
		"mode_state": mode.to_dict(),
		"achievements": Achievements.to_dict(),
	})


func _restore(data: Dictionary) -> void:
	GameFlow.selected_difficulty = int(data.get("difficulty", GameFlow.selected_difficulty))
	grid.from_dict(data.get("grid", {}))
	mode.from_dict(data.get("mode_state", {}))
	Achievements.from_dict(data.get("achievements", {}))
	phase = int(data.get("phase", Phase.USER_INPUT))
	if phase == Phase.PAUSED:
		phase = Phase.USER_INPUT
