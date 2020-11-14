extends Node2D

onready var event_manager = get_node("EventManager")

var _camera: Camera2D

func _ready():
	get_player().inventory.add_item(preload("res://scenes/items/watermelon_seeds.tres"), 30)
	get_player().inventory.add_item(preload("res://scenes/items/tomato_seeds.tres"), 20)

func set_current_camera(camera):
	camera.current = true
	_camera = camera
	
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
