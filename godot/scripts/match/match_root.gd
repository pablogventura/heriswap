extends Control

## Match loop: UserInput → Delete → Fall → Spawn (+ LevelChanged / EndGame).
## Morphs animate the view first; GridModel commits when tweens finish.
## Phase.USER_INPUT must stay 0 (see MatchInputRules.PHASE_USER_INPUT).

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
var hud_digits: AlphabetDigits
var juice: JuiceFx
var _selected_sprite: Sprite2D
var _selected_type: int = -1
var _hud_points_seen: int = -1

var drag_start: Vector2i = Vector2i(-1, -1)
var hold_timer: float = 0.0
var input_loop_time: float = 0.0
var combo_chain: int = 0
var pending_combos: Array = []
var pending_falls: Array = []
var pending_spawns: Array = []
var phase_timer: float = 0.0
var restore_paused: bool = false
var elite_pending: bool = false
var _animating: bool = false

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
	# Scene ColorRect sits above Node2D decor; hide it once craft backdrop is live.
	if has_node("ColorRect") and ResourceLoader.exists("res://assets/textures/menu/match_bg.png"):
		$ColorRect.visible = false

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
	juice = JuiceFx.new()
	juice.name = "JuiceFx"
	add_child(juice)
	juice.setup(grid_layer)
	_wire_playfield()
	_setup_hud_digits()

	var snapshot := RunSnapshot.load_run()
	var needs_intro_spawn := false
	if not snapshot.is_empty() and int(snapshot.get("mode", -1)) == GameFlow.selected_mode:
		_restore(snapshot)
		restore_paused = true
	else:
		grid.fill_until_playable()
		needs_intro_spawn = true

	await get_tree().process_frame
	_layout_grid()
	_rebuild_sprites()
	hedgehog.set_progress(mode.progress(), get_viewport_rect().size.x)
	AudioBus.stop_menu_music()
	AudioBus.start_game_music()
	SaveService.bump_game_count()
	pause_panel.visible = false
	UiTheme.style_buttons_in(pause_panel)
	UiTheme.style_button(pause_btn)
	UiTheme.wire_button_punch(pause_btn)
	pause_btn.text = "||"
	pause_btn.pressed.connect(_toggle_pause)
	hint_btn.visible = false
	$PausePanel/VBox/Resume.text = tr("continue_")
	$PausePanel/VBox/Help.text = tr("help")
	$PausePanel/VBox/Quit.text = tr("give_up")
	$PausePanel/VBox/Restart.text = tr("restart")
	$PausePanel/VBox/Resume.pressed.connect(_toggle_pause)
	$PausePanel/VBox/Help.pressed.connect(func():
		GameFlow.returning_from_match = true
		GameFlow.go_help()
	)
	$PausePanel/VBox/Quit.pressed.connect(_abort_to_menu)
	$PausePanel/VBox/Restart.pressed.connect(_restart_run)
	if mode is Go100SecondsMode:
		(mode as Go100SecondsMode).squall_started.connect(_on_squall)
	# Overlays first (IGNORE), then playfield on top so leaf drag always receives input.
	if juice and juice.flash_overlay:
		juice.flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(juice.flash_overlay, get_child_count() - 1)
	if juice and juice.combo_label:
		juice.combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(juice.combo_label, get_child_count() - 1)
	if level_label:
		level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_child(playfield, get_child_count() - 1)
	move_child($HUD, get_child_count() - 1)
	move_child(pause_panel, get_child_count() - 1)
	UiTheme.style_label(hud_label, 22)
	UiTheme.style_label(level_label, 80)
	if needs_intro_spawn:
		# Morph phases are tween/timer driven; do not leave SPAWN waiting on phase_timer.
		_begin_spawn()
	elif restore_paused:
		_toggle_pause()
	elif phase != Phase.USER_INPUT and phase != Phase.PAUSED and phase != Phase.GAME_OVER:
		# Mid-morph snapshot: return to playable input rather than stuck animating.
		phase = Phase.USER_INPUT
		_animating = false
		_swap_locked = false

func _setup_hud_digits() -> void:
	hud_digits = AlphabetDigits.new()
	hud_digits.glyph_height = 34.0
	$HUD/ScoreDigits.add_child(hud_digits)


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
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.set_anchors_preset(Control.PRESET_CENTER)
	level_label.offset_left = -260
	level_label.offset_right = 260
	level_label.offset_top = -60
	level_label.offset_bottom = 60
	add_child(level_label)

	desaturate_rect = ColorRect.new()
	desaturate_rect.visible = false
	desaturate_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	desaturate_rect.color = Color(0.5, 0.5, 0.5, 0.35)
	desaturate_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desaturate_rect)

	snow_particles = CPUParticles2D.new()
	snow_particles.emitting = false
	snow_particles.amount = 140
	snow_particles.lifetime = 3.2
	snow_particles.direction = Vector2(0.15, 1)
	snow_particles.spread = 40.0
	snow_particles.initial_velocity_min = 50.0
	snow_particles.initial_velocity_max = 160.0
	snow_particles.gravity = Vector2(0, 35)
	snow_particles.position = Vector2(400, -30)
	snow_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow_particles.emission_rect_extents = Vector2(480, 12)
	var flake := "res://assets/textures/snow/snow_flake0.png"
	if ResourceLoader.exists(flake):
		snow_particles.texture = load(flake)
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
	if phase == Phase.USER_INPUT and not _animating:
		input_loop_time += dt
		var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _dragging
		Achievements.s_what_to_do(held, dt)
		if held:
			hold_timer += dt
		else:
			hold_timer = 0.0
	if mode.finished:
		_on_mode_finished_achievements()
		_end_game()
		return
	match phase:
		Phase.LEVEL_CHANGED:
			phase_timer -= dt
			if phase_timer <= 0.0 and not _animating:
				_end_level_changed()


func _update_hud() -> void:
	hud_label.text = mode.hud_text()
	var new_prog := mode.progress() * 100.0
	if juice and new_prog > progress_bar.value + 0.4:
		juice.pulse_progress(progress_bar)
	progress_bar.value = new_prog
	if hud_digits:
		hud_digits.set_display(str(mode.points))


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


func _make_sprite(pos: Vector2i, leaf_type: int, from_scale: float = 1.0) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = leaf_textures[clampi(leaf_type, 0, leaf_textures.size() - 1)]
	spr.centered = true
	var tex_size: Vector2 = spr.texture.get_size()
	var base := cell_size * 0.9 / maxf(tex_size.x, tex_size.y)
	spr.scale = Vector2.ONE * base * from_scale
	spr.position = _cell_to_screen(pos)
	spr.set_meta("base_scale", base)
	grid_layer.add_child(spr)
	sprites[pos] = spr
	return spr


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
	if not MatchInputRules.can_accept_play_input(phase, _animating, _swap_locked):
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var pos := _event_to_root(st.position)
		if st.pressed:
			_dragging = true
			_swap_locked = false
			drag_start = _screen_to_cell(pos)
			_begin_drag_fx(drag_start, pos)
		else:
			if _dragging and not _swap_locked:
				_try_swap(drag_start, _screen_to_cell(pos))
			_end_drag_fx()
			_dragging = false
			drag_start = Vector2i(-1, -1)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _dragging or _swap_locked:
			return
		var root_pos := _event_to_root(sd.position)
		if juice:
			juice.update_trail(root_pos)
		var cell := _screen_to_cell(root_pos)
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
			_begin_drag_fx(drag_start, mpos)
		else:
			if _dragging and not _swap_locked:
				_try_swap(drag_start, _screen_to_cell(mpos))
			_end_drag_fx()
			_dragging = false
			drag_start = Vector2i(-1, -1)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if not _dragging or _swap_locked:
			return
		if not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return
		var root2 := _event_to_root(mm.position)
		if juice:
			juice.update_trail(root2)
		var cell2 := _screen_to_cell(root2)
		if cell2 != drag_start and abs(cell2.x - drag_start.x) + abs(cell2.y - drag_start.y) == 1:
			_try_swap(drag_start, cell2)


func _begin_drag_fx(cell: Vector2i, screen_pos: Vector2) -> void:
	if juice == null:
		return
	if not grid.is_valid(cell.x, cell.y):
		return
	var t: int = grid.get_cell(cell.x, cell.y)
	if t < 0:
		return
	_selected_type = t
	_selected_sprite = sprites.get(cell)
	if _selected_sprite:
		juice.apply_glow(_selected_sprite, t, 1.0)
	juice.start_trail(t)
	juice.update_trail(screen_pos)


func _end_drag_fx() -> void:
	if juice:
		juice.stop_trail()
		if _selected_sprite:
			juice.clear_glow(_selected_sprite)
	_selected_sprite = null
	_selected_type = -1


func _gui_input(_event: InputEvent) -> void:
	pass


func _try_swap(a: Vector2i, b: Vector2i) -> void:
	if _swap_locked or _animating:
		return
	if not grid.is_valid(a.x, a.y) or not grid.is_valid(b.x, b.y):
		return
	if abs(a.x - b.x) + abs(a.y - b.y) != 1:
		return
	if grid.get_cell(a.x, a.y) < 0 or grid.get_cell(b.x, b.y) < 0:
		return
	if not grid.would_swap_match(a, b):
		PlatformServices.vibrate(15)
		AudioBus.play_invalid_swap()
		if juice:
			if sprites.has(a):
				juice.wobble(sprites[a])
			if sprites.has(b):
				juice.wobble(sprites[b])
			juice.shockwave(_cell_to_screen(a), Color(0.6, 0.6, 0.65, 0.7), 48.0)
		return
	_end_drag_fx()
	_swap_locked = true
	_dragging = false
	Achievements.s_lucky_luke(input_loop_time)
	input_loop_time = 0.0
	Achievements.s_what_to_do(false, 0.0)
	_animate_swap(a, b)


func _animate_swap(a: Vector2i, b: Vector2i) -> void:
	_animating = true
	phase = Phase.USER_INPUT
	var sa: Sprite2D = sprites.get(a)
	var sb: Sprite2D = sprites.get(b)
	if sa == null or sb == null:
		grid.swap_cells(a, b)
		_rebuild_sprites()
		_animating = false
		combo_chain = 0
		_begin_delete()
		return
	var pa := sa.position
	var pb := sb.position
	var base_a: Vector2 = sa.scale
	var base_b: Vector2 = sb.scale
	var anti_dur := mini(0.09, timings.swap * 0.35)
	var move_dur := maxf(0.08, timings.swap - anti_dur)
	var start_swap := func():
		# Slight arc via midpoints
		var mid_a := pa.lerp(pb, 0.5) + Vector2(0, -10)
		var mid_b := pb.lerp(pa, 0.5) + Vector2(0, -10)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(sa, "position", mid_a, move_dur * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(sb, "position", mid_b, move_dur * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(sa, "position", pb, move_dur * 0.55).set_delay(move_dur * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(sb, "position", pa, move_dur * 0.55).set_delay(move_dur * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(sa, "scale", base_a, move_dur * 0.5)
		tw.tween_property(sb, "scale", base_b, move_dur * 0.5)
		if juice:
			juice.punch_scale(sa, base_a, 1.18, move_dur)
			juice.punch_scale(sb, base_b, 1.18, move_dur)
			juice.apply_glow(sa, grid.get_cell(a.x, a.y), 0.8)
			juice.apply_glow(sb, grid.get_cell(b.x, b.y), 0.8)
		tw.finished.connect(func():
			grid.swap_cells(a, b)
			sprites[a] = sb
			sprites[b] = sa
			if juice:
				juice.clear_glow(sa)
				juice.clear_glow(sb)
			AudioBus.play_swap()
			_animating = false
			combo_chain = 0
			_begin_delete()
		)
	if juice:
		var anti := juice.anticipate_swap(sa, sb, base_a, base_b, anti_dur)
		anti.finished.connect(start_swap)
	else:
		start_swap.call()


func _begin_delete() -> void:
	pending_combos = grid.look_for_combinations()
	if pending_combos.is_empty():
		phase = Phase.USER_INPUT
		combo_chain = 0
		_swap_locked = false
		_animating = false
		return
	combo_chain += 1
	Achievements.s_bim_bam_boum(combo_chain)
	if pending_combos.size() >= 2:
		Achievements.s_double_in_one()
	phase = Phase.DELETE
	_animating = true
	AudioBus.play_match_combo(combo_chain)
	var jscale := 1.0
	var any := false
	if juice:
		jscale = juice.juice_scale(combo_chain)
		juice.combo_banner(combo_chain)
		if combo_chain >= 2 or pending_combos.size() >= 2:
			juice.camera_punch(6.0 + combo_chain * 1.2, 0.14)
			juice.zoom_punch(0.03 + 0.01 * combo_chain, 0.16)
			juice.screen_flash(0.24 + 0.04 * combo_chain, 0.12)
		for combo in pending_combos:
			var mid := Vector2.ZERO
			var n := 0
			for p in combo.points:
				mid += _cell_to_screen(p)
				n += 1
				juice.burst_at(_cell_to_screen(p), int(combo.type), int(16.0 * jscale))
				if sprites.has(p):
					juice.apply_pop_flash(sprites[p], int(combo.type), timings.deletion * 0.45)
			if n > 0:
				mid /= float(n)
				juice.shockwave(mid, LeafPalette.color_for(int(combo.type)), 70.0 * jscale)
	for combo in pending_combos:
		var center := Vector2.ZERO
		var count := 0
		for p in combo.points:
			center += _cell_to_screen(p)
			count += 1
		if count > 0:
			center /= float(count)
		for p in combo.points:
			if not sprites.has(p):
				continue
			any = true
			var spr: Sprite2D = sprites[p]
			if juice:
				juice.explode_leaf(spr, center, timings.deletion)
			else:
				var tw := create_tween()
				tw.tween_property(spr, "scale", spr.scale * 0.05, timings.deletion)
				tw.parallel().tween_property(spr, "modulate:a", 0.0, timings.deletion)
	if not any:
		_finish_delete()
		return
	get_tree().create_timer(timings.deletion).timeout.connect(_finish_delete)


func _finish_delete() -> void:
	var all_points: Array = []
	var prev_points := mode.points
	for combo in pending_combos:
		mode.score_calc(combo.points.size(), combo.type, grid)
		_notify_achievements(mode.last_score_event)
		all_points.append_array(combo.points)
		if juice and combo.points.size() > 0:
			var mid: Vector2 = _cell_to_screen(combo.points[combo.points.size() / 2])
			var gained := mode.points - prev_points
			prev_points = mode.points
			if gained > 0:
				juice.float_text(mid, "+%d" % gained, LeafPalette.color_for(int(combo.type)))
	grid.remove_points(all_points)
	_rebuild_sprites()
	_animating = false
	_begin_fall()


func _begin_fall() -> void:
	phase = Phase.FALL
	pending_falls = grid.tile_fall()
	if pending_falls.is_empty():
		_begin_spawn()
		return
	_animating = true
	var tw := create_tween().set_parallel(true)
	var any := false
	var land_fx: Array = [] ## {pos, type}
	for f in pending_falls:
		var from := Vector2i(int(f.x), int(f.from_y))
		var to := Vector2i(int(f.x), int(f.to_y))
		if not sprites.has(from):
			continue
		any = true
		var spr: Sprite2D = sprites[from]
		var leaf_t: int = grid.get_cell(from.x, from.y)
		var land := _cell_to_screen(to)
		var overshoot := land + Vector2(0, 14.0)
		tw.tween_property(spr, "position", overshoot, timings.fall * 0.82).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(spr, "position", land, timings.fall * 0.18).set_delay(timings.fall * 0.82).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		land_fx.append({"pos": land, "type": leaf_t, "cell": to})
	if not any:
		_finish_fall_wave()
		return
	tw.finished.connect(func():
		_finish_fall_wave(land_fx)
	)


func _finish_fall_wave(land_fx: Array = []) -> void:
	grid.apply_falls(pending_falls)
	_rebuild_sprites()
	if juice:
		AudioBus.play_land()
		for info in land_fx:
			juice.dust_at(info.pos, int(info.type))
			var cell: Vector2i = info.cell
			if sprites.has(cell):
				var spr: Sprite2D = sprites[cell]
				var base: float = spr.get_meta("base_scale", cell_size * 0.015)
				juice.land_squash(spr, Vector2.ONE * base, 0.14)
	pending_falls = grid.tile_fall()
	if not pending_falls.is_empty():
		_begin_fall()
		return
	_animating = false
	if not grid.look_for_combinations().is_empty():
		_begin_delete()
		return
	_begin_spawn()


func _begin_spawn() -> void:
	phase = Phase.SPAWN
	if not grid.still_combinations():
		Achievements.mark_grid_reset()
		grid.fill_until_playable()
		_rebuild_sprites()
		_after_spawn_logic()
		return
	pending_spawns = grid.fill_blanks()
	if pending_spawns.is_empty():
		_purge_spawn_combos()
		_after_spawn_logic()
		return
	_animating = true
	_rebuild_sprites()
	var tw := create_tween().set_parallel(true)
	for p in pending_spawns:
		if not sprites.has(p):
			continue
		var spr: Sprite2D = sprites[p]
		var base: float = spr.get_meta("base_scale", cell_size * 0.015)
		var land := _cell_to_screen(p)
		spr.position = land + Vector2(0, -cell_size * 1.15)
		spr.scale = Vector2.ONE * base * 0.4
		spr.modulate.a = 0.0
		tw.tween_property(spr, "position", land + Vector2(0, 6), timings.spawn * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(spr, "position", land, timings.spawn * 0.3).set_delay(timings.spawn * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(spr, "scale", Vector2.ONE * base * 1.12, timings.spawn * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(spr, "scale", Vector2.ONE * base, timings.spawn * 0.3).set_delay(timings.spawn * 0.7)
		tw.tween_property(spr, "modulate:a", 1.0, timings.spawn * 0.5)
		if juice:
			juice.burst_at(land, grid.get_cell(p.x, p.y), 8)
	if juice and pending_spawns.size() > 0:
		AudioBus.play_spawn_pop()
	tw.finished.connect(func():
		_animating = false
		_purge_spawn_combos()
		_after_spawn_logic()
	)


func _purge_spawn_combos() -> void:
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


func _after_spawn_logic() -> void:
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
	_animating = false
	input_loop_time = 0.0
	_save_snapshot()


func _start_level_changed() -> void:
	phase = Phase.LEVEL_CHANGED
	phase_timer = timings.level_changed
	_animating = true
	if juice:
		juice.level_locked = true
		juice.stop_trail()
		juice.screen_flash(0.45, 0.18)
		juice.camera_punch(10.0, 0.2)
		juice.zoom_punch(0.06, 0.22)
		juice.confetti(get_viewport_rect().size * 0.5, 80)
		juice.shockwave(get_viewport_rect().size * 0.5, Color(1, 1, 1, 0.9), 160.0)
	level_label.text = "%s %d" % [tr("level"), mode.level]
	level_label.visible = true
	level_label.modulate.a = 0.0
	level_label.scale = Vector2(0.6, 0.6)
	desaturate_rect.visible = false
	_apply_grid_desaturate(true)
	snow_particles.emitting = true
	var tw := create_tween()
	tw.tween_property(level_label, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(level_label, "scale", Vector2(1.15, 1.15), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(level_label, "scale", Vector2.ONE, 0.15)
	tw.tween_interval(maxf(0.4, timings.level_changed - 0.85))
	tw.tween_property(level_label, "modulate:a", 0.0, 0.3)
	tw.finished.connect(func():
		_animating = false
	)
	if mode.level == 10 and GameFlow.selected_difficulty != Difficulty.HARD:
		elite_pending = true


func _end_level_changed() -> void:
	level_label.visible = false
	_apply_grid_desaturate(false)
	snow_particles.emitting = false
	if juice:
		juice.level_locked = false
	if elite_pending:
		elite_pending = false
		phase = Phase.SPAWN
		_swap_locked = false
		_save_snapshot()
		GameFlow.go_elite()
		return
	hedgehog.setup_skins(mode.bonus_type)
	_begin_spawn()


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
	if juice:
		juice.camera_punch(12.0, 0.22)
		juice.zoom_punch(0.07, 0.2)
		juice.screen_flash(0.4, 0.15)
		juice.confetti(Vector2(200, 400), 48)
		juice.burst_at(Vector2(100, 500), bonus, 40)
		juice.shockwave(Vector2(200, 520), LeafPalette.color_for(bonus), 140.0)
	_spawn_squall_leaves(bonus)


func _spawn_squall_leaves(bonus: int) -> void:
	var tex: Texture2D = leaf_textures[clampi(bonus, 0, leaf_textures.size() - 1)]
	for i in 48:
		var body := RigidBody2D.new()
		body.gravity_scale = 0.28
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale = Vector2(0.35 + (i % 3) * 0.08, 0.35 + (i % 3) * 0.08)
		body.add_child(spr)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		shape.shape = circle
		body.add_child(shape)
		body.position = Vector2(-120.0 - (i % 12) * 28.0, 140.0 + (i % 8) * 55.0)
		body.linear_velocity = Vector2(320.0 + i * 10.0 + randf_range(0, 80), randf_range(-80.0, 90.0))
		body.angular_velocity = randf_range(-5.0, 5.0)
		add_child(body)
		var killer := get_tree().create_timer(3.2)
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
			var leaf_t: int = grid.get_cell(p.x, p.y)
			if juice:
				juice.hint_pulse(spr, leaf_t)
			var tw := create_tween()
			tw.tween_property(spr, "rotation", deg_to_rad(18), 0.12)
			tw.tween_property(spr, "rotation", deg_to_rad(-18), 0.12)
			tw.tween_property(spr, "rotation", 0.0, 0.12)


func _toggle_pause() -> void:
	if phase == Phase.GAME_OVER or _animating:
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
	if mode is NormalMode:
		Achievements.s_666_loser(mode.level)
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
