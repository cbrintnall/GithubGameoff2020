extends Node2D

signal do_tick

export(PackedScene) var tilled_land_scene = preload("res://scenes/tilled_land.tscn")

export(NodePath) onready var fence_tilemap = get_node(fence_tilemap) as TileMap
export(NodePath) onready var dirt_tilemap = get_node(dirt_tilemap) as TileMap
export(NodePath) onready var audio_player = get_node(audio_player)
export(NodePath) onready var moon = get_node(moon)

export(int) var untilled_dirt_tile
export(int) var tilled_dirt_tile

onready var tick_timer = get_node("Timer")

var in_bounds_tiles = []
var till_sound = preload("res://assets/audio/till.wav")
var TileData = preload("res://scenes/scripts/tile_data.gd")

# keys are vects, values are whatever is stored at that location
var data_storage = {  }

func _ready():
#	_load_data_storage_with_cells()
	_update_in_bound_tiles()
	
	moon.connect("do_pulse", self, "_on_pulse")
	var tm = dirt_tilemap as TileMap
	var moon_tile = tm.world_to_map(moon.position)
	
	tick_timer.connect("timeout", self, "_do_tick")
	
	for tile in tm.get_used_cells():
		var distance_to_moon = tile.distance_to(moon_tile)
#		var data = get_data_at(tile)
#
#		if distance_to_moon <= moon.max_distance_in_tiles:
#			data.set_distance(distance_to_moon, moon.max_distance_in_tiles)
#		else:
#			data.set_distance(-1, moon.max_distance_in_tiles)

func _do_tick():
	emit_signal("do_tick")
	tick_timer.start()

func _update_in_bound_tiles():
	var fenced_tiles = fence_tilemap.get_used_cells()
	var dirt_tiles = dirt_tilemap.get_used_cells()
	
	for cell in dirt_tiles:
		if !(cell in fenced_tiles):
			in_bounds_tiles.append(cell)

func _on_pulse(energy):
	var tm = dirt_tilemap as TileMap
	var moon_tile = tm.world_to_map(moon.position)
	
	for tilled in data_storage:
		var tilled_land = data_storage[tilled]
		if tilled_land.has_method("give_energy"):
			tilled_land.give_energy(energy)

func _load_data_storage_with_cells():
	var tm = dirt_tilemap as TileMap

	if tm:
		for cell in tm.get_used_cells():
			_set_cell_to_default_state(cell)

func _set_cell_to_default_state(vec: Vector2):
	data_storage[vec] = TileData.new()

func to_world(vec: Vector2) -> Vector2:
	return dirt_tilemap.map_to_world(vec)

# TODO: correct this to account for fences
func get_inbounds_rect() -> Rect2:
	return dirt_tilemap.get_used_rect()

func cell_in_bounds(cell: Vector2):
	return cell in in_bounds_tiles

func is_tilled(vec: Vector2):
	return vec in data_storage

func till_dirt(vec: Vector2):
	if !cell_in_bounds(vec):
		return
	
	var new_patch = tilled_land_scene.instance()
	new_patch.position = dirt_tilemap.map_to_world(vec)
	add_child(new_patch)
	
	data_storage[vec] = new_patch
	audio_player.stream = till_sound
	audio_player.play()

func get_data_at(vec: Vector2):
	if vec in data_storage:
		return data_storage[vec]
		
	return null
