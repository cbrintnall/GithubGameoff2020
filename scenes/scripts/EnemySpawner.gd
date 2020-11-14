extends Node2D

export(float) var spawn_rate = 5.0
export(PackedScene) var enemy

onready var _path = get_node("Path2D")

var _cached_layer_root

func _ready():
	_cached_layer_root = get_node("/root/GameManager/WorldLayering")
	
	while true:
		_do_spawn()
		yield(get_tree().create_timer(spawn_rate),"timeout")

func _do_spawn():
	var new_enemy = enemy.instance()
	
	new_enemy.global_position = global_position
	
	if new_enemy.has_method("set_path"):
		new_enemy.set_path(global_position, _path.get_curve())
	else:
		print("Enemy didn't have a set_path method!")

	_cached_layer_root.add_child(new_enemy)
