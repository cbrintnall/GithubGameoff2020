extends Node2D

class_name Exploder

export(float) var impulse_strength := 250.0

var _ground_item := preload("res://scenes/items/ground_item.tscn")
var _flipped_dir := 1

var _items := { }

func explode_at(items, at: Vector2):
	global_position = at
	
	if items is Array:
		set_items(items)
	if items is Dictionary:
		set_items_amt(items)
		
	explode()

func set_items(items: Array):
	for item in items:
		_items[item] = 1

func set_items_amt(items: Dictionary):
	_items = items
	
func explode():
	var root = get_tree().root
	
	for item in _items:
		var ground_item = _ground_item.instance()
		var direction = Vector2(rand_range(-1, 1), rand_range(-1, 1)) * _flipped_dir
		
		_flipped_dir = -_flipped_dir
		
		root.add_child(ground_item)
		
		ground_item.global_position = global_position
		ground_item.z_index = z_index
		ground_item.set_item(item)
		ground_item.set_quantity(_items[item])
		ground_item.apply_central_impulse(direction * (impulse_strength * rand_range(1, 1.5)))
		
	queue_free()
