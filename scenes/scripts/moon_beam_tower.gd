extends Tower

export(float) var beam_scalar_max = 30
export(Gradient) var base_beam_gradient
export(Gradient) var too_close_gradient

onready var charge_particles = get_node("CPUParticles2D")
onready var tween = get_node("Tween")
onready var line_beam = get_node("Beam/Line2D")
onready var beam_tween = get_node("Beam/Tween")

func _ready():
	line_beam.points = PoolVector2Array()

func _charge():
	._charge()

	tween.interpolate_property(
		charge_particles,
		"emission_sphere_radius",
		30,
		3,
		charge_timer.wait_time,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	
	tween.interpolate_property(
		charge_particles,
		"orbit_velocity",
		0,
		3,
		charge_timer.wait_time,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	
	tween.start()

func _shoot_at_target(target):
	_shoot_beam_at_point(target, target.global_position)

func _shoot_beam_at_point(shot_at, point: Vector2):
	# only fire if they can actually take damage.
	if !shot_at.has_method("take_damage"):
		return

	_set_state(TowerState.FIRING)
	
	shot_at.take_damage(damage_per_hit * damage_multiplier)
	
	var vectors = PoolVector2Array()
	var target_point = point-global_position
	var dir = Vector2.ZERO.direction_to(target_point)
	var distance = Vector2.ZERO.distance_to(target_point)
	
	vectors.append(Vector2.ZERO)
	
	var offset_scalar = 1 if rand_range(0, 101) < 50 else -1
	var max_range = int(clamp(floor(distance/10)-1, 1, INF))
		
	for i in range(1, max_range):
		var base_point = dir * (distance - (distance/i))
		var offset = rand_range(10, beam_scalar_max) * offset_scalar
		
		vectors.append(base_point + (Vector2.RIGHT * offset))
		
		offset_scalar *= -1
	
	vectors.append(target_point)

	line_beam.gradient = base_beam_gradient if distance > 30 else too_close_gradient
	line_beam.points = vectors
	
	if shoot_audio:
		audio_player.stream = shoot_audio
		audio_player.play()
	
	yield(get_tree().create_timer(.5), "timeout")

	# clear the beam
	line_beam.points = PoolVector2Array()
	_set_state(TowerState.UNCHARGED)

func _do_fire():
	var target = _get_random_target()
	var progress = target.get_path_progress() if target.has_method("get_path_progress") else 0.0
	
	print(progress)
	
	_shoot_at_target(target)
