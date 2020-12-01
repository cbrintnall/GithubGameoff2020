extends Tower

"""
this is the only place damage increases currently happen, if we need to add
more we need to use a dictionary approach where the key is the source and value is
the multiplier, then a towers damage is multiplied by the sum of the dictionary's values
"""

onready var base_particles = get_node("Particles2D")

export(int) var max_effected_towers := 1
export(float) var damage_increase = 2.0

var _beam_scene := preload("res://scenes/towers/lunar_pool/path_effect.tscn")
var _tower_beam_cache := {}

func _ready():
	get_node("CheckTimer").connect("timeout", self, "_on_timeout")

# this is so stupid, there seems to be a bug where collision isn't properly
# checking this layer initially, so we flip the bit on a timer to force a check
func _on_timeout():
	var va = vision_area as Area2D
	va.set_collision_layer_bit(15,!va.get_collision_layer_bit(15))

# override parent purchase method, use this to set our signal connections
func purchase():
	.purchase()
	
	connect("lost_target", self, "_on_lost_target")
	connect("new_target", self, "_on_new_target")
	
func _on_lost_target(target):
	if target is Tower and _tower_beam_cache.has(target):
		target.reset_damage_multiplier()
		_tower_beam_cache[target].queue_free()
		_tower_beam_cache.erase(target)
	
func _on_new_target(target):
	if target is Tower and _tower_beam_cache.size() < max_effected_towers:
		target.set_damage_multiplier(damage_increase)
		
		_tower_beam_cache[target] = _beam_scene.instance()
		base_particles.add_child(_tower_beam_cache[target])
		_tower_beam_cache[target].set_target(target)
