extends Node2D

signal item_added(item)
signal item_removed(item)

onready var game_manager = get_node("/root/GameManager")

# dictionary of item, int
var items = {  }

func get_items():
	return items.keys()

func get_item_quantity(item: Item) -> int:
	if item in items:
		return items[item]
	else:
		return 0

func add_item(item: Item, amt := 1):
	if !(item in items):
		items[item] = 0
		
	items[item] += amt
	
	emit_signal("item_added", item)
	game_manager.event_manager.new_message("Received {amt} {item}{post}".format({
		"amt": amt, 
		"item": item.item_name,
		"post": "s" if amt > 1 else ""
	}))
	
func remove_item(item: Item, amt := 1):
	if !(item in items):
		return

	items[item] -= amt
	
	if items[item] <= 0:
		items.erase(item)

	emit_signal("item_removed", item)
	game_manager.event_manager.new_message("Lost {amt} {item}{post}".format({
		"amt": amt, 
		"item": item.item_name,
		"post": "s" if amt > 1 else ""
	}))
