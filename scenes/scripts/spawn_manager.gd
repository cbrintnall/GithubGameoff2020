extends Node2D

export(String) var wave_file_path
export(Array, NodePath) var spawner_paths

onready var game_manager = get_node("/root/GameManager")
onready var farm_manager = game_manager.get_farm_manager()
onready var event_manager = game_manager.get_event_manager()

var spawners := []

var _wave_data := {}
var _loaded_enemies := {}

func _ready():
	var prefs = game_manager.get_node(Constants.PLAYER_PREFS_PATH)
	prefs.register_command("spawner", funcref(self, "_handle_commands"))
	game_manager.get_farm_manager().connect("night", self, "spawn_new_wave")

	for spawner in spawner_paths:
		spawners.append(get_node(spawner))

	sync_wave_data()

# dummy arg so dev console can pass "args" to it, which we won't use
func sync_wave_data(noop := []):
	var file_data = read_wave_file()
	var json = JSON.parse(file_data)
	
	if json.error == OK:
		_wave_data = json.result
		
		_loaded_enemies = {}
		var enemy_paths = _wave_data["enemy_paths"]
		for enemy in enemy_paths:
			_loaded_enemies[enemy] = load(enemy_paths[enemy])
	else:
		print("error reading wave data!")

func read_wave_file() -> Dictionary:
	var file = File.new()
	var path = wave_file_path if wave_file_path else Constants.MAIN_WAVES_PATH

	file.open(path, File.READ)
	var contents = file.get_as_text()
	file.close()
	return contents

func use():
	spawn_new_wave()

# generates a new wave, then spawns it
func spawn_new_wave():
	spawn_wave(generate_wave())

# @param day is used to determine the difficulty of the wave
func generate_wave(day: int = farm_manager.day, offset := 1):
	var difficulty_requirement = day + offset
	var waves: Array = _wave_data["waves"]
	var chosen_waves := []

	waves.sort_custom(self, "_sort_waves_by_difficulty")
	
	# god this is whole thing is disgusting
	while difficulty_requirement > 0:
		for spawner in spawners:
			for wave in waves:
				var modified_difficulty = wave["difficulty"] * spawner.difficulty_modifier
				if modified_difficulty <= difficulty_requirement:
					difficulty_requirement -= modified_difficulty

					var wave_data = { "spawner": spawner, "wave": {} }
					
					for enemy in wave["enemies"]:
						var enemy_scene = _loaded_enemies[enemy]

						wave_data["wave"][enemy_scene] = wave["enemies"][enemy]

					chosen_waves.append(wave_data)

	return chosen_waves

func spawn_wave(waves):
	var cheap_set := {}
	
	for wave in waves:
		var spawner = wave["spawner"]
		
		spawner.set_wave(wave["wave"])
		spawner.start_wave()
		
		cheap_set[spawner] = false
	
	# use a dictionary to remove duplicates
	if event_manager:
		for spawner in cheap_set.keys():
			var message = "Enemies coming from the {direction}".format({"direction": spawner.name.to_lower()})
			event_manager.new_message(message, Constants.EventLevel.WARNING)

func _handle_commands(args: Array):
	match args:
		[ "generate" ]:
			print(generate_wave())
		[ "generate", var day ]:
			print(generate_wave(int(day)))
		[ "generate", var day, var offset ]:
			print(generate_wave(int(day), int(offset)))
		[ "spawn", "new" ]:
			spawn_new_wave()

# puts the higher difficulties first
func _sort_waves_by_difficulty(a, b):
	return a["difficulty"] > b["difficulty"]
