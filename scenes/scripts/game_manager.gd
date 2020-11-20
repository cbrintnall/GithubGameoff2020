extends Node2D

export(NodePath) var largest_tilemap

onready var event_manager = get_node("EventManager")

var _camera: Camera2D

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
