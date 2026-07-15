extends Control

## Match loop: UserInput → Delete → Fall → Spawn (+ LevelChanged / EndGame).

enum Phase { USER_INPUT, DELETE, FALL, SPAWN, LEVEL_CHANGED, PAUSED, GAME_OVER }

var grid: GridModel
var mode: GameModeBase
var phase: int = Phase.USER_INPUT
var cell_size: float = 64.0
var grid_origin: Vector2 = Vector2.ZERO
var leaf_textures: Array = []
var sprites: Dictionary = {}
var timings: TimingConfig
var branch_view: BranchLeavesView
var hedgehog: HedgehogActor
var decor: MatchDecor
var snow_particles: CPUParticles2D
var level_label: Label
var desaturate_rect: ColorRect

var drag_start: Vector2i = Vector2i(-1, -1)
var hold_timer: float = 0.0
var combo_chain: int = 0
var pending_combos: Array = []
var phase_timer: float = 0.0
var restore_paused: bool = false
var elite_pending: bool = false

@onready var grid_layer: Node2D = $GridLayer
@onready var playfield: Control = $PlayfieldInput
@onready var hud_label: Label = $HUD/ScoreLabel
@onready var progress_bar: ProgressBar = $HUD/ProgressBar
@onready var pause_panel: Panel = $PausePanel
@onready var hint_btn: Button = $HUD/HintButton
@onready var pause_btn: Button = $HUD/PauseButton

var _dragging: bool = false
var _swap_locked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if has_node("ColorRect"):
		$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_textures()
	timings = TimingConfig.for_difficulty(GameFlow.selected_difficulty)
	grid = GridModel.new()
	grid.set_difficulty(GameFlow.selected_difficulty)
	mode = GameModeBase.create(GameFlow.selected_mode)
	mode.enter(GameFlow.selected_difficulty, GameFlow.start_level)

	decor = MatchDecor.new()
	add_child(decor)
	move_child(decor, 0)

	branch_view = BranchLeavesView.new()
	add_child(branch_view)
	branch_view.setup(leaf_textures)
	if mode.has_method("bind_branch"):
		mode.bind_branch(branch_view)

	hedgehog = HedgehogActor.new()
	add_child(hedgehog)
	hedgehog.setup_skins(mode.bonus_type)
	hedgehog.tapped.connect(_on_hint)

	_setup_fx_nodes()
	_wire_playfield()

	var snapshot := RunSnapshot.load_run()
	if not snapshot.is_empty() and int(snapshot.get("mode", -1)) == GameFlow.selected_mode:
		_restore(snapshot)
		restore_paused = true
	else:
		grid.fill_until_playable()
		phase = Phase.SPAWN
		phase_timer = timings.spawn

	await get_tree().process_frame
	_layout_grid()
	_rebuild_sprites()
	hedgehog.set_progress(mode.progress(), get_viewport_rect().size.x)
	AudioBus.stop_menu_music()
	AudioBus.start_game_music()
	SaveService.bump_game_count()
	pause_panel.visible = false
	pause_btn.text = "||"
	pause_btn.pressed.connect(_toggle_pause)
	hint_btn.visible = false
	$PausePanel/VBox/Resume.text = tr("continue_")
	$PausePanel/VBox/Help.text = tr("help")
	$PausePanel/VBox/Quit.text = tr("give_up")
	if not $PausePanel/VBox.has_node("Restart"):
		var restart := Button.new()
		restart.name = "Restart"
		restart.text = tr("restart")
		$PausePanel/VBox.add_child(restart)
		$PausePanel/VBox.move_child(restart, 1)
	$PausePanel/VBox/Resume.pressed.connect(_toggle_pause)
	$PausePanel/VBox/Help.pressed.connect(func():
		GameFlow.returning_from_match = true
		GameFlow.go_help()
	)
	$PausePanel/VBox/Quit.pressed.connect(_abort_to_menu)
	$PausePanel/VBox/Restart.pressed.connect(_restart_run)
	if mode is Go100SecondsMode:
		(mode as Go100SecondsMode).squall_started.connect(_on_squall)
	# Keep playfield above world visuals but under HUD/pause.
	move_child(playfield, get_child_count() - 1)
	move_child($HUD, get_child_count() - 1)
	move_child(pause_panel, get_child_count() - 1)
	UiTheme.style_label(hud_label, 28)
	if restore_paused:
		_toggle_pause()


func _wire_playfield() -> void:
	if playfield == null:
		playfield = Control.new()
		playfield.name = "PlayfieldInput"
		playfield.set_anchors_preset(Control.PRESET_FULL_RECT)
		playfield.offset_top = 150.0
		add_child(playfield)
	playfield.mouse_filter = Control.MOUSE_FILTER_STOP
	playfield.gui_input.connect(_on_playfield_input)


func _setup_fx_nodes() -> void:
	level_label = Label.new()
	level_label.visible = false
	level_label.add_theme_font_size_override("font_size", 72)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.set_anchors_preset(Control.PRESET_CENTER)
	level_label.offset_left = -200
	level_label.offset_right = 200
	level_label.offset_top = -40
	level_label.offset_bottom = 40
	add_child(level_label)

	desaturate_rect = ColorRect.new()
	desaturate_rect.visible = false
	desaturate_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	desaturate_rect.color = Color(0.5, 0.5, 0.5, 0.35)
	desaturate_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desaturate_rect)

	snow_particles = CPUParticles2D.new()
	snow_particles.emitting = false
	snow_particles.amount = 80
	snow_particles.lifetime = 2.5
	snow_particles.direction = Vector2(0, 1)
	snow_particles.spread = 30.0
	snow_particles.initial_velocity_min = 40.0
	snow_particles.initial_velocity_max = 120.0
	snow_particles.gravity = Vector2(0, 40)
	snow_particles.position = Vector2(400, -20)
	snow_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow_particles.emission_rect_extents = Vector2(420, 10)
	add_child(snow_particles)


func _load_textures() -> void:
	leaf_textures.clear()
	for i in range(1, 9):
		leaf_textures.append(load("res://assets/textures/feuilles/feuille%d.png" % i))


func _layout_grid() -> void:
	if grid == null:
		return
	var rect := get_viewport_rect().size
	if size.x > 1.0:
		rect = size
	var margin := 40.0
	var avail_w := rect.x - margin * 2.0
	var avail_h := rect.y * 0.48
	cell_size = mini(avail_w / float(grid.grid_size), avail_h / float(grid.grid_size))
	var total := cell_size * float(grid.grid_size)
	grid_origin = Vector2((rect.x - total) * 0.5, rect.y * 0.34)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if grid == null:
			return
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
	if grid == null or mode == null:
		return
	if decor:
		decor.scroll(dt, 0.4 + mode.progress())
	mode.update(dt, grid)
	Achievements.tick(dt)
	if hedgehog:
		hedgehog.set_progress(mode.progress(), get_viewport_rect().size.x)
	if mode is NormalMode:
		AudioBus.set_stress((mode as NormalMode).stress_amount())
	_update_hud()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and phase == Phase.USER_INPUT:
		hold_timer += dt
		if hold_timer >= 5.0:
			Achievements.s_what_to_do()
	else:
		hold_timer = 0.0
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
				_end_level_changed()


func _update_hud() -> void:
	hud_label.text = mode.hud_text()
	progress_bar.value = mode.progress() * 100.0


func _rebuild_sprites() -> void:
	if grid == null or grid_layer == null:
		return
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
	var screen_y := float(grid.grid_size - 1 - pos.y)
	return grid_origin + Vector2((float(pos.x) + 0.5) * cell_size, (screen_y + 0.5) * cell_size)


func _screen_to_cell(screen: Vector2) -> Vector2i:
	var local := screen - grid_origin
	var x := int(local.x / cell_size)
	var screen_y := int(local.y / cell_size)
	var y := grid.grid_size - 1 - screen_y
	return Vector2i(x, y)


func _event_to_root(local_in_playfield: Vector2) -> Vector2:
	if playfield == null:
		return local_in_playfield
	return local_in_playfield + playfield.position


func _on_playfield_input(event: InputEvent) -> void:
	if phase != Phase.USER_INPUT or _swap_locked:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var pos := _event_to_root(st.position)
		if st.pressed:
			_dragging = true
			_swap_locked = false
			drag_start = _screen_to_cell(pos)
		else:
			if _dragging and not _swap_locked:
				_try_swap(drag_start, _screen_to_cell(pos))
			_dragging = false
			drag_start = Vector2i(-1, -1)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _dragging or _swap_locked:
			return
		var cell := _screen_to_cell(_event_to_root(sd.position))
		if cell != drag_start and abs(cell.x - drag_start.x) + abs(cell.y - drag_start.y) == 1:
			_try_swap(drag_start, cell)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var mpos := _event_to_root(mb.position)
		if mb.pressed:
			_dragging = true
			_swap_locked = false
			drag_start = _screen_to_cell(mpos)
		else:
			if _dragging and not _swap_locked:
				_try_swap(drag_start, _screen_to_cell(mpos))
			_dragging = false
			drag_start = Vector2i(-1, -1)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if not _dragging or _swap_locked:
			return
		if not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return
		var cell2 := _screen_to_cell(_event_to_root(mm.position))
		if cell2 != drag_start and abs(cell2.x - drag_start.x) + abs(cell2.y - drag_start.y) == 1:
			_try_swap(drag_start, cell2)


func _gui_input(_event: InputEvent) -> void:
	# PlayfieldInput owns gameplay clicks.
	pass


func _try_swap(a: Vector2i, b: Vector2i) -> void:
	if _swap_locked:
		return
	if not grid.is_valid(a.x, a.y) or not grid.is_valid(b.x, b.y):
		return
	if abs(a.x - b.x) + abs(a.y - b.y) != 1:
		return
	if grid.get_cell(a.x, a.y) < 0 or grid.get_cell(b.x, b.y) < 0:
		return
	if not grid.would_swap_match(a, b):
		PlatformServices.vibrate(15)
		return
	_swap_locked = true
	_dragging = false
	grid.swap_cells(a, b)
	AudioBus.play_swap()
	_rebuild_sprites()
	combo_chain = 0
	_begin_delete()


func _begin_delete() -> void:
	pending_combos = grid.look_for_combinations()
	if pending_combos.is_empty():
		phase = Phase.USER_INPUT
		combo_chain = 0
		_swap_locked = false
		return
	combo_chain += 1
	Achievements.s_bim_bam_boum(combo_chain)
	if pending_combos.size() >= 2:
		Achievements.s_double_in_one()
	phase = Phase.DELETE
	phase_timer = timings.deletion
	AudioBus.play_match()
	for combo in pending_combos:
		for p in combo.points:
			if sprites.has(p):
				var spr: Sprite2D = sprites[p]
				var tw := create_tween()
				tw.tween_property(spr, "rotation", deg_to_rad(12.0), timings.deletion * 0.25)
				tw.tween_property(spr, "rotation", deg_to_rad(-12.0), timings.deletion * 0.25)
				tw.parallel().tween_property(spr, "scale", spr.scale * 0.15, timings.deletion)


func _finish_delete() -> void:
	var all_points: Array = []
	for combo in pending_combos:
		mode.score_calc(combo.points.size(), combo.type, grid)
		_notify_achievements(mode.last_score_event)
		all_points.append_array(combo.points)
	grid.remove_points(all_points)
	_rebuild_sprites()
	phase = Phase.FALL
	phase_timer = timings.fall


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
	phase_timer = timings.spawn


func _finish_spawn() -> void:
	if not grid.still_combinations():
		Achievements.mark_grid_reset()
		grid.fill_until_playable()
	else:
		grid.fill_blanks()
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
		_start_level_changed()
		return
	if mode.finished:
		_on_mode_finished_achievements()
		_end_game()
		return
	combo_chain = 0
	phase = Phase.USER_INPUT
	_swap_locked = false
	_dragging = false
	_save_snapshot()


func _start_level_changed() -> void:
	phase = Phase.LEVEL_CHANGED
	phase_timer = timings.level_changed
	level_label.text = "%s %d" % [tr("level"), mode.level]
	level_label.visible = true
	desaturate_rect.visible = false
	_apply_grid_desaturate(true)
	snow_particles.emitting = true
	if mode.level == 10 and GameFlow.selected_difficulty != Difficulty.HARD:
		elite_pending = true


func _end_level_changed() -> void:
	level_label.visible = false
	_apply_grid_desaturate(false)
	snow_particles.emitting = false
	if elite_pending:
		elite_pending = false
		phase = Phase.SPAWN
		phase_timer = timings.spawn
		_swap_locked = false
		_save_snapshot()
		GameFlow.go_elite()
		return
	hedgehog.setup_skins(mode.bonus_type)
	phase = Phase.SPAWN
	phase_timer = timings.spawn
	_rebuild_sprites()


func _apply_grid_desaturate(on: bool) -> void:
	var mat: ShaderMaterial = null
	if on and ResourceLoader.exists("res://assets/shaders/desaturate.gdshader"):
		mat = ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/desaturate.gdshader")
	for spr in sprites.values():
		if is_instance_valid(spr):
			spr.material = mat


func _on_squall(bonus: int) -> void:
	hedgehog.setup_skins(bonus)
	AudioBus.play_match()
	_spawn_squall_leaves(bonus)


func _spawn_squall_leaves(bonus: int) -> void:
	var tex: Texture2D = leaf_textures[clampi(bonus, 0, leaf_textures.size() - 1)]
	for i in 24:
		var body := RigidBody2D.new()
		body.gravity_scale = 0.35
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale = Vector2(0.4, 0.4)
		body.add_child(spr)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 18.0
		shape.shape = circle
		body.add_child(shape)
		body.position = Vector2(-80.0 - i * 30.0, 180.0 + (i % 5) * 40.0)
		body.linear_velocity = Vector2(380.0 + i * 12.0, randf_range(-40.0, 60.0))
		body.angular_velocity = randf_range(-4.0, 4.0)
		add_child(body)
		var killer := get_tree().create_timer(2.8)
		killer.timeout.connect(func():
			if is_instance_valid(body):
				body.queue_free()
		)


func _on_hint() -> void:
	if mode is NormalMode and not (mode as NormalMode).help_available:
		return
	var hint: Array = grid.find_hint()
	if hint.size() < 2:
		return
	for p in hint:
		if sprites.has(p):
			var spr: Sprite2D = sprites[p]
			var tw := create_tween()
			tw.tween_property(spr, "rotation", deg_to_rad(18), 0.12)
			tw.tween_property(spr, "rotation", deg_to_rad(-18), 0.12)
			tw.tween_property(spr, "rotation", 0.0, 0.12)
			tw.parallel().tween_property(spr, "modulate", Color(2, 2, 1), 0.2)
			tw.tween_property(spr, "modulate", Color.WHITE, 0.2)


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


func _restart_run() -> void:
	RunSnapshot.clear()
	GameFlow.begin_run(GameFlow.selected_mode, GameFlow.selected_difficulty, GameFlow.start_level)


func _abort_to_menu() -> void:
	if mode is NormalMode and mode.level == 6:
		Achievements.s_666_loser()
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
	Achievements.s_lucky_luke_note_combo()


func _on_mode_finished_achievements() -> void:
	if mode.mode_id() == GameModeBase.MODE_TILES_ATTACK and mode.won:
		Achievements.s_fast_and_finish(mode.time_sec)
		Achievements.s_reset_grid()
	Achievements.s_take_your_time()
	Achievements.s_they_good(SaveService.is_high_score(
		mode.mode_id(), GameFlow.selected_difficulty, mode.points, mode.time_sec
	))


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
	Achievements.s_test_everything(SaveService.load_scores())
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
	timings = TimingConfig.for_difficulty(GameFlow.selected_difficulty)
	grid.from_dict(data.get("grid", {}))
	mode.from_dict(data.get("mode_state", {}))
	if mode.has_method("bind_branch"):
		mode.bind_branch(branch_view)
	Achievements.from_dict(data.get("achievements", {}))
	phase = int(data.get("phase", Phase.USER_INPUT))
	if phase == Phase.PAUSED:
		phase = Phase.USER_INPUT
