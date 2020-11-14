extends KinematicBody2D

export(float) var speed = 2.0

onready var animation = get_node("AnimatedSprite")
onready var damage_tween = get_node("Tween")

var internal_path: PoolVector2Array
var max_health := 100.0
var health := max_health

var _next_point: int
var _moving := true
var _moon

func _ready():
	_moon = get_node("/root/GameManager").get_moon()

func _physics_process(delta):
	if _moving:
		_do_move(delta)

func _do_move(delta):
	if internal_path and len(internal_path) < 0:
		return

	var target_point = internal_path[_next_point]
	
	if global_position.distance_to(target_point) < 1:
		_next_point = _next_point + 1

		if _next_point == internal_path.size():
			_moving = false
		else:
			target_point = internal_path[_next_point]
	
	move_and_collide(
		(target_point - global_position).normalized() * speed * delta
	)

func set_path(base: Vector2, _path: Curve2D):
	if !is_inside_tree():
		yield(self,"ready")

	internal_path = _path.get_baked_points()
	
	for i in range(0, internal_path.size()):
		internal_path[i] += base

func take_damage(amt: float):
	health -= amt
	var total_duration = .25

	if health <= 0:
		_die()
		return

	damage_tween.interpolate_property(
		animation,
		"modulate",
		Color.white,
		Color.red,
		total_duration/2,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	
	damage_tween.start()
	
	yield(damage_tween,"tween_all_completed")
	
	damage_tween.interpolate_property(
		animation,
		"modulate",
		Color.red,
		Color.white,
		total_duration/2,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)

	damage_tween.start()
	
func _die():
	queue_free()
