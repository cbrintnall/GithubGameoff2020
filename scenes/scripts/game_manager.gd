extends Node2D

export(NodePath) var entity_ysort_path
export(NodePath) var largest_tilemap

onready var end_screen = get_node("GameOverScreen")
onready var event_manager = get_node("EventManager")

var _camera: Camera2D

#func _ready():
#	var to_free_on_exit := [
#		get_player(),
#		get_farm_manager(),
#		get_node("SpawnManager")
#	]
#
#	get_moon().connect(
#		"broken", 
#		end_screen, 
#		"begin_end", 
#		[ get_farm_manager().day, to_free_on_exit ]
#	)

func lock_camera_to_map(tilemap: TileMap):
	if !_camera:
		return

	var bounds = Rect2(
		tilemap.get_used_rect().position * tilemap.cell_size,
		tilemap.get_used_rect().size * tilemap.cell_size
	)

	_camera.limit_bottom = bounds.end.y
	_camera.limit_right = bounds.end.x
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y

func set_current_camera(camera: Camera2D):
	camera.current = true
	_camera = camera

func get_ground_manager():
	return get_node("GroundManager")

func get_event_manager():
	return event_manager

func get_player_prefs():
	return get_node(Constants.PLAYER_PREFS_PATH)

func get_current_camera() -> Camera2D:
	return _camera

func get_player():
	return get_node("WorldLayering/Player")

func get_entity_parent() -> YSort:
	return get_node(entity_ysort_path) as YSort

func get_farm_manager():
	return get_node(Constants.FARM_MANAGER_PATH)

func get_music_manager():
	return get_node("MusicManager")

func get_moon():
	return get_node("moon")
