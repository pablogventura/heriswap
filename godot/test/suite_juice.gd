extends RefCounted


static func run(tree: SceneTree) -> int:
	var failed := 0
	failed += TestHarness.approx("juice scale 1", JuiceFx.new().juice_scale(1), 1.0)
	failed += TestHarness.approx("juice scale 2", JuiceFx.new().juice_scale(2), 1.12)
	failed += TestHarness.approx("juice scale capped", JuiceFx.new().juice_scale(20), 1.6)
	failed += TestHarness.expect("palette 0 opaque", LeafPalette.color_for(0).a > 0.9)
	failed += TestHarness.expect("palette 7 valid", LeafPalette.color_for(7).r >= 0.0)
	failed += TestHarness.expect("palette clamps", LeafPalette.color_for(99) == LeafPalette.color_for(7))

	var juice := JuiceFx.new()
	tree.root.add_child(juice)
	var shake := Node2D.new()
	tree.root.add_child(shake)
	juice.setup(shake)
	failed += TestHarness.expect("flash overlay ignore", juice.flash_overlay != null and juice.flash_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	failed += TestHarness.expect("combo label ignore", juice.combo_label != null and juice.combo_label.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	failed += TestHarness.expect("spark texture", juice._spark != null)
	failed += TestHarness.expect("star texture", juice._star != null)
	failed += TestHarness.expect("ring texture", juice._ring != null)

	juice.burst_at(Vector2(100, 100), 2, 10)
	juice.shockwave(Vector2(50, 50), Color.WHITE, 40.0)
	juice.dust_at(Vector2(10, 10), 1)
	failed += TestHarness.expect("juice fx spawned children", juice.get_child_count() >= 1)

	var pts: Array = [Vector2(80, 80), Vector2(120, 80), Vector2(100, 120)]
	juice.telegraph_match(pts, Color(1, 0.6, 0.3), 0.05)
	juice.telegraph_stripe(Vector2(100, 100), true, 80.0, Color(1, 0.9, 0.4), 0.05)
	juice.telegraph_bomb(Vector2(100, 100), pts, Color(0.5, 0.9, 1.0), 0.05)
	juice.telegraph_wrapped(Vector2(100, 100), Color(1, 0.5, 0.8), 0.05, 40.0)
	juice.telegraph_fish(Vector2(100, 100), pts, Color(1, 0.9, 0.4), 0.05)
	failed += TestHarness.expect("telegraph spawned", juice._telegraph_nodes.size() >= 1 or juice.get_child_count() >= 1)
	juice.clear_telegraphs()
	failed += TestHarness.expect("telegraph cleared", juice._telegraph_nodes.is_empty())

	var prev_rm = SaveService.options.get("reduce_motion", false)
	SaveService.options["reduce_motion"] = true
	juice.telegraph_match(pts, Color.WHITE, 0.1)
	failed += TestHarness.expect("reduce_motion skips telegraph", juice._telegraph_nodes.is_empty())

	var demo := Sprite2D.new()
	tree.root.add_child(demo)
	demo.position = Vector2(40, 40)
	demo.scale = Vector2(1, 1)
	demo.rotation = 0.3
	juice.paper_flip(demo, Vector2.ONE, 0.2)
	juice.paper_spin_flutter(demo, 0.2)
	juice.land_shadow_flash(demo, 0.2)
	failed += TestHarness.expect("reduce_motion skips paper flip residual", is_equal_approx(demo.scale.x, 1.0))
	demo.rotation = 0.0
	juice.fall_flutter(demo, Vector2(40, 0), Vector2(40, 40), 0.2)
	failed += TestHarness.expect("reduce_motion fall snaps to land", demo.position == Vector2(40, 40))
	failed += TestHarness.expect("reduce_motion fall clears rotation", is_equal_approx(demo.rotation, 0.0))

	var decor := MatchDecor.new()
	tree.root.add_child(decor)
	var punch_before := decor._punch_offset
	decor.parallax_punch(20.0, 0.1)
	failed += TestHarness.expect("reduce_motion skips parallax punch", decor._punch_offset == punch_before)
	SaveService.options["reduce_motion"] = prev_rm

	demo.queue_free()
	decor.queue_free()
	juice.queue_free()
	shake.queue_free()
	return failed
