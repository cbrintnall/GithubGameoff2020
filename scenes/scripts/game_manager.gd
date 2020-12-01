extends Node2D

export(NodePath) var largest_tilemap

onready var end_screen = get_node("GameOverScreen")
onready var event_manager = get_node("EventManager")

var _camera: Camera2D

func _ready():
	var to_free_on_exit := [
		get_player(),
		get_farm_manager(),
		get_node("SpawnManager")
	]
	
	get_moon().connect(
		"broken", 
		end_screen, 
		"begin_end", 
		[ get_farm_manager().day, to_free_on_exit ]
	)

func set_current_camera(camera: Camera2D):
	var map = get_node(largest_tilemap) as TileMap
	camera.current = true
	
	if map:
		var bounds = Rect2(
			map.get_used_rect().position * map.cell_size,
			map.get_used_rect().size * map.cell_size
		)
	
		camera.limit_bottom = bounds.end.y
		camera.limit_right = bounds.end.x
		camera.limit_left = bounds.position.x
		camera.limit_top = bounds.position.y
	
	_camera = camera

func get_ground_manager():
	return get_node("GroundManager")

func get_event_manager():
	return event_manager

func get_player_prefs():
	return get_node("PlayerPrefs")

func get_current_camera() -> Camera2D:
	return _camera

func get_player():
	return get_node("WorldLayering/Player")

func get_farm_manager():
	return get_node("FarmManager")

func get_music_manager():
	return get_node("MusicManager")

func get_moon():
	return get_node("moon")
