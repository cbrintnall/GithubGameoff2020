extends Path2D

export(float) var spawn_rate = 5.0
export(PackedScene) var enemy

onready var _spawn_timer = get_node("Timer")

var _cached_layer_root
var _should_spawn := false

func _ready():
	var farm_manager = get_node("/root/GameManager").get_farm_manager()

	farm_manager.connect("night", self, "_on_night")
	farm_manager.connect("day", self, "_on_day")
	
	_cached_layer_root = get_node("/root/GameManager/WorldLayering")
	_spawn_timer.wait_time = spawn_rate
	_spawn_timer.connect("timeout", self, "_on_timeout")

func _on_timeout():
	if _should_spawn:
		_do_spawn()

func _on_night():
	_should_spawn = true
	
func _on_day():
	_should_spawn = false

func _do_spawn():
	var new_enemy = enemy.instance()
	
	new_enemy.global_position = global_position
	
	if new_enemy.has_method("set_path"):
		new_enemy.set_path(global_position, get_curve())
	else:
		print("Enemy didn't have a set_path method!")

	_cached_layer_root.add_child(new_enemy)
