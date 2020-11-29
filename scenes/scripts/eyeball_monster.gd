extends KinematicBody2D

export(Vector2) var attack_offset := Vector2(-30, 0)
export(float) var damage := 0
export(float) var speed := 2.0
export(NodePath) onready var animation = get_node(animation) as AnimatedSprite

onready var damage_tween = get_node("Tween")

var internal_path: PoolVector2Array
var max_health := 100.0
var health := max_health
var progress: float = 0.0

var _attack_timer: Timer
var _next_point: int
var _moving := true
var _moon
var _direction

func get_path_progress() -> float:
	if internal_path.size() == 0:
		return 0.0
	
	return float(_next_point)/float(internal_path.size())

func _ready():
	var game_manager = get_node("/root/GameManager")
	_moon = game_manager.get_moon()
	game_manager.get_farm_manager().connect("day", self, "_on_day")

# make monsters die during the day!
func _on_day():
	_die()

func _on_attack_timeout():
	animation.play("attack")

	#TODO: remove, absolute last minute hack
	if name == "EyeballMonster":
		animation.flip_h = global_position.direction_to(_moon.global_position).x < 0

	#gross
	var frame_count = animation.frames.get_frame_count("attack")
	for i in frame_count:
		if i >= (frame_count/2):
			_moon.take_damage(damage)
			break
		yield(animation,"frame_changed")
	yield(animation,"animation_finished")

func _physics_process(delta):
	if _moving:
		_do_move(delta)
	elif _next_point == internal_path.size()-1 and !_attack_timer:
		_attack_timer = Timer.new()
		_attack_timer.wait_time = 3.5
		_attack_timer.autostart = true
		_attack_timer.one_shot = false
		_attack_timer.connect("timeout", self, "_on_attack_timeout")
		add_child(_attack_timer)
		_on_attack_timeout()

func _do_move(delta):
	if !internal_path:
		return

	#TODO: remove, absolute last minute hack
	var is_target_for_hack = (_next_point==(internal_path.size()-2) and name == "EyeballMonster")
	var target_point = internal_path[_next_point] + (-attack_offset if is_target_for_hack else Vector2.ZERO)
	
	_direction = (target_point - global_position).normalized()
	animation.flip_h = _direction.x < 0
	
	if global_position.distance_to(target_point) < 3.0:
		_next_point = _next_point + 1

		if _next_point == internal_path.size()-1:
			_moving = false
		else:
			target_point = internal_path[_next_point]
	
	progress = _next_point / internal_path.size()
	move_and_collide(_direction * speed * delta)

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
	_moving = false
	animation.play("die")
	yield(animation,"animation_finished")
	queue_free()
