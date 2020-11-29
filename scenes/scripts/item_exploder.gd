extends Node2D

export(float) var impulse_strength := 500.0

var _ground_item := preload("res://scenes/items/ground_item.tscn")
var _flipped_dir := 1

var _items := { }

func set_items(items: Array):
	for item in items:
		_items[item] = 1

func set_items_amt(items: Dictionary):
	_items = items
	
func explode():
	for item in _items:
		var ground_item = _ground_item.instance()
		var direction = Vector2(rand_range(-1, 1), rand_range(-1, 1)) * _flipped_dir
		
		_flipped_dir = -_flipped_dir
		
		add_child(ground_item)
		
		ground_item.z_index = z_index
		ground_item.set_item(item)
		ground_item.set_quantity(_items[item])
		ground_item.apply_central_impulse(direction * (impulse_strength * rand_range(1, 2)))
