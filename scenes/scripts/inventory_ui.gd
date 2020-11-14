extends Control

export(int) var slots_per_row = 9
export(int) var slots = 18

export(PackedScene) var slot_scene

export(NodePath) onready var player_inventory = get_node(player_inventory)
export(NodePath) onready var grid_parent = get_node(grid_parent) as VBoxContainer

var current_slots := []

func _ready():
	_set_slots()
	close_inventory()
	
	player_inventory.connect("item_added", self, "_on_item_added")
	player_inventory.connect("item_removed", self, "_on_item_removed")
	
func _get_first_open_slot():
	for slot in current_slots:
		if slot.is_open():
			return slot
			
	return null

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
		var storage_slot = _get_first_open_slot()
		
		if storage_slot:
			storage_slot.set_item(item)
			storage_slot.set_quantity(
				player_inventory.get_item_quantity(item)
			)
	else:
		var existing_slot = _get_slot_with_item(item)
		existing_slot.set_quantity(
			player_inventory.get_item_quantity(item)
		)

func _on_item_removed(item):
	print("removed " + str(item))

func open_inventory():
	visible = true
	
func close_inventory():
	visible = false

func _unhandled_input(event):
	if event.is_action_pressed("open_inventory"):
		if visible:
			close_inventory()
		else:
			open_inventory()
	if event.is_action_pressed("close_inventory"):
		close_inventory()

func _set_slots():
	var slot_rows = ceil(slots/slots_per_row)
	
	for i in range(0, slot_rows):
		var grid = GridContainer.new()
		
		grid.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.columns = slots_per_row
		
		grid_parent.add_child(grid)
		
		for j in range(0, slots_per_row):
			var new_slot = slot_scene.instance()
			grid.add_child(new_slot)
			current_slots.append(new_slot)
