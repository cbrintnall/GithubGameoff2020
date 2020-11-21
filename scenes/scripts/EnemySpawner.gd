extends Path2D

signal wave_finished

class_name EnemySpawner

export(int) var difficulty_modifier
export(float) var spawn_rate = 5.0
export(NodePath) onready var world_layering = get_node(world_layering)
export(PackedScene) var enemy

onready var _spawn_timer = get_node("Timer")

var _should_spawn := false
var _current_wave: Dictionary

func set_wave(wave: Dictionary):
	_current_wave = wave

func start_wave():
	for enemy in _current_wave:
		for count in range(0, _current_wave[enemy]):
			_spawn_enemy(enemy)
			_spawn_timer.start()
			yield(_spawn_timer, "timeout")

	emit_signal("wave_finished", _current_wave)
	_current_wave = {}

func _ready():
	var farm_manager = get_node("/root/GameManager").get_farm_manager()
	_spawn_timer.wait_time = spawn_rate

func _spawn_enemy(enemy: PackedScene):
	var new_enemy = enemy.instance()
	
	new_enemy.global_position = global_position
	
	if new_enemy.has_method("set_path"):
		new_enemy.set_path(global_position, get_curve())
	else:
		print("Enemy didn't have a set_path method!")

	world_layering.add_child(new_enemy)
