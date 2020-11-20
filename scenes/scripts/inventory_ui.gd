extends Control

export(int) var slots_per_row = 9
export(int) var slots = 18

export(PackedScene) var slot_scene

export(NodePath) onready var player_inventory = get_node(player_inventory)
export(NodePath) onready var slots_parent = get_node(slots_parent) as VBoxContainer

var current_slots := []

func _ready():
	player_inventory.connect("item_added", self, "_on_item_added")
	player_inventory.connect("item_removed", self, "_on_item_removed")

func _slot_has_item(item: Item):
	for slot in current_slots:
		if slot.has_item(item):
			return true
			
	return false

func _get_slot_with_item(item):
	for slot in current_slots:
		if slot.has_item(item):
			return slot
			
	return null

func _on_item_added(item):
	var no_slot = _slot_has_item(item)
	
	if !no_slot:
		var storage_slot = slot_scene.instance()
		
		slots_parent.add_child(storage_slot)
		
		if storage_slot:
			storage_slot.set_item(item)
			storage_slot.set_quantity(
				player_inventory.get_item_quantity(item)
			)
			current_slots.append(storage_slot)
	else:
		var existing_slot = _get_slot_with_item(item)
		existing_slot.set_quantity(
			player_inventory.get_item_quantity(item)
		)

func _on_item_removed(item):
	var existing_slot = _get_slot_with_item(item)
	
	if existing_slot:
		existing_slot.set_quantity(
			player_inventory.get_item_quantity(item)
		)
