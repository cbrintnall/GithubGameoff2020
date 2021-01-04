extends Tower

signal shot_beam

export(bool) var beam_lightning := false
export(int) var max_targets := 3
export(float) var beam_scalar_max = 30
export(Gradient) var base_beam_gradient
export(Gradient) var too_close_gradient

onready var root = get_tree().root
onready var beam_root = get_node("VariableNodes/BeamRoot")
onready var charge_particles = get_node("MoonTop/CPUParticles2D")
onready var tween = get_node("Tween")

var _beam = preload("res://scenes/towers/moon_beam.tscn")
var _points_and_targets := {}

func get_upgrades() -> Array:
	return [
		{
			"name": "Beams",
			"generator_func": "upgrade_beam",
			"setter_func": "set_beam_upgrade"
		}
	]

func _ready():
	var mat = $TowerBody.material as ShaderMaterial
#	mat.set_shader_param("charge_amount", 0.0)

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
	if target:
		_shoot_beam_at_point(target, target.global_position)

func _shoot_beam_at_point(shot_at, point: Vector2):
	# unused atm, but code left in just in case
	if beam_lightning:
		var vectors := []
		var target_point = point-global_position
		var dir = Vector2.ZERO.direction_to(target_point)
		var distance = Vector2.ZERO.distance_to(target_point)
		var offset_scalar = 1 if rand_range(0, 101) < 50 else -1
		var max_range = int(clamp(floor(distance/10)-1, 1, INF))
			
		for i in range(1, max_range):
			var base_point = dir * (distance - (distance/i))
			var offset = rand_range(10, beam_scalar_max) * offset_scalar
			
			vectors.append(base_point + (Vector2.RIGHT * offset))

			offset_scalar *= -1
	
	var beam_parent = _beam.instance()
	root.add_child(beam_parent)
	beam_parent.global_position = beam_root.global_position
	beam_parent.set_target(shot_at, damage_per_hit*damage_multiplier)
	beam_parent.z_index = z_index + 1
	
	if shoot_audio:
		audio_player.stream = shoot_audio
		audio_player.play()
	
	yield(beam_parent, "tree_exited")

	emit_signal("shot_beam")

func _sort_by_progress(a, b):
	var a_progress = a.get_path_progress() if a.has_method("get_path_progress") else 0.0
	var b_progress = b.get_path_progress() if b.has_method("get_path_progress") else 0.0
	
	return a_progress > b_progress

func _sort_by_health(a, b):
	var a_progress = a.get_health() if a.has_method("get_health") else 0
	var b_progress = b.get_health() if b.has_method("get_health") else 0
	
	return a_progress > b_progress

func _get_targets_based_on_mode():
	var local_targets = targets.duplicate()
		
	# position based target modes
	if _target_mode in [Constants.TowerTargetMode.FIRST,Constants.TowerTargetMode.LAST,Constants.TowerTargetMode.RANDOM]:
		local_targets.sort_custom(self, "_sort_by_progress")
		
	# health based target modes
	if _target_mode in [Constants.TowerTargetMode.LOWEST_HEALTH, Constants.TowerTargetMode.HIGHEST_HEALTH]:
		local_targets.sort_custom(self, "_sort_by_health")

	if len(local_targets) == 0:
		return []

	# we can only combine FIRST / HIGHEST_HEALTH due to the sorting in the line before,
	# if this sorting changes then this must too
	match _target_mode:
		Constants.TowerTargetMode.FIRST, Constants.TowerTargetMode.HIGHEST_HEALTH:
			return local_targets[0]
		Constants.TowerTargetMode.LAST, Constants.TowerTargetMode.LOWEST_HEALTH:
			return local_targets[len(local_targets)-1]
		Constants.TowerTargetMode.RANDOM:
			return local_targets[randi()%len(local_targets)]
			
	return []

func _set_state(state):
	._set_state(state)

	var mat = $TowerBody.material as ShaderMaterial

#	match state:
#		TowerState.CHARGED:
#			mat.set_shader_param("charge_amount", 1.0)
#		_:
#			mat.set_shader_param("charge_amount", 0.0)

# add focus mode. meaning it will pick one target and fire everything into it
func _do_fire():
	_set_state(TowerState.FIRING)

	var tree = get_tree()

	for i in range(max_targets):
		_shoot_at_target(_get_targets_based_on_mode())
		yield(tree.create_timer(0.25), "timeout")

	_set_state(TowerState.UNCHARGED)

#func _process(delta):
#	var mat = $TowerBody.material as ShaderMaterial
#	mat.set_shader_param("charge_amount", normalized_charge_process())
