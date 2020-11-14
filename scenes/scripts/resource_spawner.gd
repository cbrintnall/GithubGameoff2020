extends Node2D

export(PackedScene) var resource_scene
export(NodePath) onready var ground_manager = get_node(ground_manager)
export(NodePath) onready var world_entities_parent = get_node(world_entities_parent)

#poisson params
var radius = 5.0
var retries = 30.0

# max number of resources on map at a given moment
var max_points = 10
# when resource emits signal destroyed, decrement this, when spawning, increment
var current_count = 0
var _points_queue := []
var _sampler := PoissonDiscSampling.new()

func _ready():
	get_node("Timer").connect("timeout", self, "_on_timer")

func _generate_points():
	_points_queue = _sampler.generate_points(radius, ground_manager.get_inbounds_rect(), retries)

func _spawn_wave():
	if current_count < max_points:
		var point = _points_queue[randi() % _points_queue.size()]
		var world_point = ground_manager.to_world(point.floor())
		var new_instance = resource_scene.instance()
		
		new_instance.connect("destroyed", self, "_on_resource_destroyed")
		new_instance.position = world_point
		
		world_entities_parent.add_child(new_instance)
		
		current_count += 1

func _on_resource_destroyed(destroyed):
	current_count -= 1
	var loot = destroyed.get_loot_table()
	
	for i in loot:
		if rand_range(0, 101) <= loot[i]:
			get_node("/root/GameManager").get_player().inventory.add_item(i)

func _on_timer():
	_generate_points()
	_spawn_wave()
