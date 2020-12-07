extends Path2D

signal wave_finished

class_name EnemySpawner

export(bool) var is_debug := false
export(int) var difficulty_modifier
export(float) var spawn_rate = 5.0
export(NodePath) onready var world_layering = get_node(world_layering)
export(PackedScene) var enemy

var _spawn_timer: Timer
var _should_spawn := false
var _current_wave: Dictionary

func set_wave(wave: Dictionary):
	_current_wave = wave

func start_wave():
	_spawn_timer.start()
	
	for _enemy in _current_wave:
		if !_current_wave.has(_enemy):
			continue

		for _count in range(0, _current_wave[_enemy]):
			_spawn_enemy(_enemy)
			
			# break if the spawn is interrupted
			if _spawn_timer.is_stopped():
				break

			yield(_spawn_timer, "timeout")
			
			if !_current_wave:
				break

	emit_signal("wave_finished", _current_wave)
	_current_wave = {}

func _ready():
	var game_manager = get_node(Constants.GAME_MANAGER_PATH)
	var farm_manager = game_manager.get_farm_manager()
	
	# stop the timer when day comes
	farm_manager.connect("day", _spawn_timer, "stop")

	if !is_debug:
		game_manager.get_moon().connect("broken", _spawn_timer, "stop")
	
	_spawn_timer = Timer.new()
	_spawn_timer.autostart = false
	_spawn_timer.wait_time = spawn_rate

	add_child(_spawn_timer)

func _on_day():
	pass

func _spawn_enemy(_enemy: PackedScene):
	var new_enemy = _enemy.instance()
	
	new_enemy.global_position = global_position
	
	if new_enemy.has_method("set_path"):
		new_enemy.set_path(global_position, get_curve())
	else:
		print("Enemy didn't have a set_path method!")

	world_layering.add_child(new_enemy)
