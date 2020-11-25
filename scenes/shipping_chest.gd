extends Area2D

"""
TODO: handle no sellable items case
"""

signal open
signal closed
signal item_deposited(item, amount)

export(float) var duration = 10.0

onready var game_manager = get_node("/root/GameManager")
onready var item_chooser = get_node("ItemChooser")
onready var animated_sprite = get_node("AnimatedSprite")
onready var move_tween = get_node("Tween")
onready var rocket_particles = get_node("CPUParticles2D")
onready var value_label = get_node("ValueLabel")
onready var quantity_root = get_node("VBoxContainer")
onready var quantity_label = get_node("VBoxContainer/QuantityLabel")
onready var quantity_change_audio = get_node("VBoxContainer/AudioStreamPlayer2D")
onready var up = get_node("VBoxContainer/Up")
onready var down = get_node("VBoxContainer/Down")

var resting_position: Vector2
var locked: bool
var open: bool
# item, amt.. could use inventory, but too lazy
var items := {}
var current_quantity := 0

func on_action_hover():
	# if locked don't do anything
	if locked:
		return

	animated_sprite.play("open")
	yield(animated_sprite,"animation_finished")
	open=true
	value_label.visible = true
	quantity_root.visible = true
	_sync_options_chooser()

func on_action_leave():
	animated_sprite.play("close")
	yield(animated_sprite,"animation_finished")
	open=false
	value_label.visible = false
	quantity_root.visible = false
	item_chooser.disable()

func use():
	# if locked, shouldn't be able to use
	if locked:
		return

	var option = item_chooser.get_current_option()
	
	if option:
		_deposit_item(option, current_quantity)
		_sync_options_chooser()

func _sync_options_chooser():
	var options = _get_sellable_items()
	
	if len(options) == 0:
		item_chooser.disable()
		quantity_root.visible = false
		value_label.visible = false
		return
	
	item_chooser.set_options(options)
	_set_side_text(item_chooser.get_current_option())
	item_chooser.enable()

func _deposit_item(item: Item, amt: int):
	# verify we have enough items to actual do this deposit!
	if game_manager.get_player().inventory.get_item_quantity(item) < amt:
		return
	
	game_manager.get_player().inventory.remove_item(item, amt)

	if !(item in items):
		items[item] = 0
		
	items[item] += amt

func _handle_quantity_change_input(event):
	if !open:
		return

	if event.is_action_pressed("select_next_alt"):
		up.modulate = Color.black
	elif event.is_action_pressed("select_previous_alt"):
		down.modulate = Color.black

	if event.is_action_released("select_next_alt"):
		var option = item_chooser.get_current_option()
		var amt = game_manager.get_player().inventory.get_item_quantity(option)
		up.modulate = Color.white
		quantity_change_audio.play()
		current_quantity = int(clamp(current_quantity+1, 1, amt))
		quantity_label.text = str(current_quantity)
		if option:
			value_label.text = "$" + str(option.value * current_quantity)
	elif event.is_action_released("select_previous_alt"):
		var option = item_chooser.get_current_option()
		var amt = game_manager.get_player().inventory.get_item_quantity(option)
		down.modulate = Color.white
		quantity_change_audio.play()
		current_quantity = int(clamp(current_quantity-1, 1, amt))
		quantity_label.text = str(current_quantity)
		value_label.text = "$" + str(option.value * current_quantity)

func _input(event):
	_handle_quantity_change_input(event)

func _ready():
	item_chooser.disable()
	item_chooser.connect("new_selection", self, "_set_side_text")
	value_label.visible = false
	quantity_root.visible = false
	
	game_manager.get_farm_manager().connect("day", self, "_come_back")
	game_manager.get_farm_manager().connect("shipment_time", self, "_take_off")
	
	resting_position = position
	
	rocket_particles.emitting = false
	
func _do_sale():
	var grand_total := 0
	
	for item in items:
		grand_total += item.value * items[item]
	
	items = {}
	
	game_manager.get_farm_manager().add_lunar_rocks(grand_total)
	game_manager.get_event_manager().new_message(
		"You sold {rocks} worth of goods".format({"rocks": grand_total}),
		Constants.EventLevel.GOOD
	)

func _come_back():
	rocket_particles.emitting = true
	
	move_tween.interpolate_property(
		self,
		"position",
		position,
		resting_position,
		duration,
		Tween.TRANS_EXPO,
		Tween.EASE_IN
	)
	
	move_tween.start()
	game_manager.get_current_camera().shake(duration, 25.0, 5.0)
	
	yield(move_tween,"tween_all_completed")
	
	rocket_particles.emitting = false
	locked = false
	
	game_manager.get_event_manager().new_message(
		"The shipping container has returned!",
		Constants.EventLevel.GOOD
	)

func _take_off():
	locked = true
	var target = Vector2.UP * (get_viewport_rect().size.y)
	
	rocket_particles.emitting = true
	
	move_tween.interpolate_property(
		self,
		"position",
		resting_position,
		resting_position + target,
		duration,
		Tween.TRANS_EXPO,
		Tween.EASE_IN
	)
	
	move_tween.start()
	game_manager.get_current_camera().shake(duration, 25.0, 10.0)
	
	game_manager.get_event_manager().new_message(
		"The shipping container is leaving",
		Constants.EventLevel.WARNING
	)
	
	yield(move_tween,"tween_all_completed")
	
	rocket_particles.emitting = false
	_do_sale()

func _set_side_text(item: Item):
	if !item:
		return
	# TODO: Lets use an icon for showing the type of money, we don't use dollars here
	current_quantity = game_manager.get_player().inventory.get_item_quantity(item)
	value_label.text = "$" + str(item.value * current_quantity)
	quantity_label.text = str(current_quantity)

func _get_sellable_items():
	var items := []
	var player = game_manager.get_player()
	
	for item in player.inventory.get_items():
		if item.value and item.value > 0:
			items.append(item)
			
	return items
