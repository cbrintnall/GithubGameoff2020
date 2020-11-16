extends StaticBody2D

enum TowerState {
	INVALID_PLACEMENT,
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
export(Texture) var icon_texture

onready var no_place_area = get_node("Area2D")
onready var collision_zone = get_node("CollisionShape2D")
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

func purchase():
	_set_state(TowerState.UNCHARGED)
	
	get_node("Area2D/CollisionShape2D").disabled = true

func can_place() -> bool:
	return state != TowerState.INVALID_PLACEMENT

func _ready():
	vision_area.connect("body_entered", self, "_on_body_enter")
	vision_area.connect("body_exited", self, "_on_body_exit")
	charge_timer.connect("timeout", self, "_on_finish_charging")
	
	no_place_area.connect("body_entered", self, "_on_collision_enter")
	no_place_area.connect("body_exited", self, "_on_collision_exit")
	no_place_area.connect("area_entered", self, "_on_collision_enter")
	no_place_area.connect("area_exited", self, "_on_collision_exit")
	
	charge_timer.wait_time = charge_time
	line_beam.points = PoolVector2Array()
	
	_set_state(TowerState.PURCHASING)

func _on_collision_exit(body):
	_set_state(TowerState.PURCHASING)

func _on_collision_enter(body):
	_set_state(TowerState.INVALID_PLACEMENT)

# handle state initialization here
func _set_state(_state):
	match _state:
		TowerState.UNCHARGED:
			pass
		TowerState.CHARGED:
			pass
		TowerState.FIRING:
			pass
		TowerState.PURCHASING:
			var color = Color.aqua
			color.a = .4
			modulate = color
			collision_zone.disabled = true
		TowerState.CHARGING:
			pass
		TowerState.INVALID_PLACEMENT:
			var color = Color.red
			color.a = .4
			modulate = color
	
	if _state != TowerState.PURCHASING and _state != TowerState.INVALID_PLACEMENT:
		modulate = Color.white
		collision_zone.disabled = false
	
	state = _state

func _get_random_target():
	return targets[int(floor(rand_range(0, len(targets)-1)))]

func _shoot_at_target(target):
	_shoot_beam_at_point(target, target.global_position)

func _shoot_beam_at_point(shot_at, point: Vector2):
	_set_state(TowerState.FIRING)
	
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
	_set_state(TowerState.UNCHARGED)

func _charge():
	_set_state(TowerState.CHARGING)
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
