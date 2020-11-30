extends Node2D

export(PackedScene) var resource_scene
export(NodePath) onready var ground_manager = get_node(ground_manager)
export(NodePath) onready var world_entities_parent = get_node(world_entities_parent)

onready var collider_check_ray = get_node("RayCast2D")

#poisson params
var radius = 5.0
var retries = 30.0

# max number of resources on map at a given moment
var max_points = 30
# when resource emits signal destroyed, decrement this, when spawning, increment
var current_count = 0
var _points_queue := []
var _sampler := PoissonDiscSampling.new()
var _exploder := preload("res://scenes/scripts/item_exploder.gd")

func _ready():
	get_node("Timer").connect("timeout", self, "_on_timer")

func _generate_points():
	_points_queue = _sampler.generate_points(radius, ground_manager.get_inbounds_rect(), retries)

func _spawn_wave():
	var found_point = false
	while current_count < max_points and !found_point and _points_queue.size() > 0:
		var point_idx = randi() % _points_queue.size()
		var point = _points_queue[point_idx]
		var world_point = ground_manager.to_world(point.floor())
		
		collider_check_ray.global_position = world_point
		collider_check_ray.force_raycast_update()
		
		if !collider_check_ray.is_colliding():
			var new_instance = resource_scene.instance()
			new_instance.connect("destroyed", self, "_on_resource_destroyed")
			new_instance.position = world_point
			world_entities_parent.add_child(new_instance)
			current_count += 1
			found_point = true
		else:
			_points_queue.remove(point_idx)

func _on_resource_destroyed(destroyed):
	current_count -= 1
	var loot = destroyed.get_loot_table()
	var gained_items := []
	
	for i in loot:
		if rand_range(0, 101) <= loot[i]:
			gained_items.append(i)
	
	var loot_explosion = _exploder.new()
	
	get_tree().root.add_child(loot_explosion)
	
	loot_explosion.explode_at(gained_items, destroyed.global_position)

func _on_timer():
	_generate_points()
	_spawn_wave()
