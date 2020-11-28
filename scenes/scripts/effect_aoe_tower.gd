extends Tower

onready var charge_tween = get_node("Tween")
onready var gas_particles = get_node("Particles2D")
onready var vision_shape = get_node("VisionArea/CollisionShape2D")

func _ready():
	connect("state_changed", self, "_on_state_changed")

func _do_fire():
	var feasible_targets := []
	
	for target in targets:
		if target.has_method("take_damage"):
			feasible_targets.append(target)

	if len(feasible_targets) == 0:
		return
	
	_set_state(TowerState.FIRING)

	for target in feasible_targets:
		target.take_damage(damage_per_hit * damage_multiplier)

	animation.play("fire")

	yield(animation, "animation_finished")

	animation.play("default")
	
	_set_state(TowerState.UNCHARGED)
