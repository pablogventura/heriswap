class_name HedgehogActor
extends Area2D

signal tapped

var progress: float = 0.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _collision: CollisionShape2D


func _ready() -> void:
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		add_child(sprite)
	_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 48.0
	_collision.shape = shape
	add_child(_collision)
	input_pickable = true


func setup_skins(bonus_type: int = 0) -> void:
	var frames := SpriteFrames.new()
	var anim := "default"
	frames.add_animation(anim)
	frames.set_animation_speed(anim, 6.0)
	frames.set_animation_loop(anim, true)
	var skin := clampi(bonus_type + 1, 1, 8)
	for f in range(1, 4):
		var path := "res://assets/textures/feuilles/herisson_%d_%d.png" % [skin, f]
		if ResourceLoader.exists(path):
			frames.add_frame(anim, load(path))
	if frames.get_frame_count(anim) == 0:
		var fallback := "res://assets/textures/feuilles/herisson_2_5.png"
		if ResourceLoader.exists(fallback):
			frames.add_frame(anim, load(fallback))
	sprite.sprite_frames = frames
	sprite.play(anim)
	sprite.scale = Vector2(0.55, 0.55)


func set_progress(p: float, viewport_w: float = 800.0) -> void:
	progress = clampf(p, 0.0, 1.0)
	position.x = lerpf(48.0, viewport_w - 48.0, progress)
	position.y = 200.0


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit()
	elif event is InputEventScreenTouch and event.pressed:
		tapped.emit()
