extends StaticBody2D

enum TowerState {
	PURCHASING,
	UNCHARGED,
	CHARGING,
	CHARGED,
	FIRING
}

const tower_detectable_layer = 262144

export(float) var value = 100.0
export(float) var damage_per_hit = 10
export(float) var beam_scalar_max = 30
export(float) var charge_time = 2.5
export(Gradient) var base_beam_gradient
export(Gradient) var too_close_gradient
export(AudioStream) var shoot_audio
export(AudioStream) var charging_audio

onready var charge_particles = get_node("CPUParticles2D")
onready var tween = get_node("Tween")
onready var vision_area = get_node("TargetZone")
onready var animation = get_node("AnimatedSprite")
onready var audio_player = get_node("VariableNodes/ChargeAudio")
onready var charge_timer = get_node("VariableNodes/ChargeTimer")
onready var line_beam = get_node("Beam/Line2D")
onready var beam_tween = get_node("Beam/Tween")

var state: int = TowerState.UNCHARGED
var targets := []

var _line_wind_down_time = .5

func _ready():
	charge_timer.wait_time = charge_time
	
	vision_area.connect("body_entered", self, "_on_body_enter")
	vision_area.connect("body_exited", self, "_on_body_exit")
	charge_timer.connect("timeout", self, "_on_finish_charging")
	
	line_beam.points = PoolVector2Array()
	state = TowerState.PURCHASING
	
	var color = Color.aqua
	color.a = .4
	
	modulate = color

func _set_state(_state):
	pass

func _purchase():
	modulate = Color.white

func _get_random_target():
	return targets[int(floor(rand_range(0, len(targets)-1)))]

func _shoot_at_target(target):
	_shoot_beam_at_point(target, target.global_position)

func _shoot_beam_at_point(shot_at, point: Vector2):
	state = TowerState.FIRING
	
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
		
	if shot_at.has_method("take_damage"):
		shot_at.take_damage(damage_per_hit)
	
	yield(get_tree().create_timer(.5), "timeout")

	# clear the beam
	line_beam.points = PoolVector2Array()
	state = TowerState.UNCHARGED

func _charge():
	state = TowerState.CHARGING
	charge_timer.start()
	
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

func _on_finish_charging():
	animation.play("default")
	state = TowerState.CHARGED

func _on_body_enter(body: PhysicsBody2D):
	if body and body.get_collision_layer_bit(18):
		targets.append(body)
	
func _on_body_exit(body):
	if body in targets:
		targets.erase(body)

func _process(delta):
	if state == TowerState.UNCHARGED:
		_charge()

	if state == TowerState.CHARGED and len(targets) > 0:
		var target = _get_random_target()
		
		_shoot_at_target(target)
