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

	juice.queue_free()
	shake.queue_free()
	return failed
