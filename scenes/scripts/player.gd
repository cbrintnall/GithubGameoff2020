extends KinematicBody2D

enum Tool {
	HOE,
	AXE,
	PICKAXE
}

export(float) var max_action_distance := 40.0
export(float) var speed = 10.0
export(Vector2) var tilemap_size = Vector2(16, 16)
export(Color) var valid_selection_color = Color.green
export(Color) var invalid_selection_color = Color.red
export(NodePath) onready var dirt_tilemap_path = get_node(dirt_tilemap_path)
export(NodePath) onready var ground_manager = get_node(ground_manager)

onready var tools_ui = get_node("ToolsUi")
onready var game_manager = get_node("/root/GameManager")
onready var event_manager = get_node("/root/GameManager/EventManager")
onready var bad_action_player = get_node("BadAction")
onready var step_particles = get_node("footsteps/Steps")
onready var footsteps_particles = get_node("footsteps/Puffs")
onready var footsteps_timer = get_node("footsteps/Timer")
onready var action_area = get_node("ActionArea")
onready var animated_sprite = get_node("AnimatedSprite")
onready var inventory = get_node("Inventory")

var selected_tool = Tool.HOE

var hovered_tile: Vector2
var last_move_vec: Vector2
var move_vec_multiplier: Vector2 = Vector2.ONE
var last_hovered_tile: Vector2
var last_areas := []
var last_bodies := []

var _current_tower_scene: PackedScene
var _current_tower_purchase
var _controller_action_area := false

func _ready():
	game_manager.set_current_camera(get_node("Camera2D"))
	footsteps_timer.connect("timeout", get_node("footsteps/audio"), "play")
	action_area.visible = true
	
	# setup the tower ui (formermly tools_ui..)
	tools_ui.connect("tower_selected", self, "_initiate_tower_transaction")
	tools_ui.connect("tower_purchase_failed", self, "_tower_purchase_failed")
	tools_ui.register_tower(KEY_1, preload("res://scenes/towers/moon_beam_tower.tscn"))
	tools_ui.register_tower(KEY_2, preload("res://scenes/towers/EffectAoeTower.tscn"))
	tools_ui.register_tower(KEY_3, preload("res://scenes/towers/lunar_pool.tscn"))
	
	var input_handler = game_manager.get_player_prefs().get_input_handler()
	
	input_handler.connect("input_mode_changed", self, "_on_input_mode_changed")
	_controller_action_area = input_handler.input_mode == Constants.InputMode.CONTROLLER

func _on_input_mode_changed(mode):
	_controller_action_area = mode == Constants.InputMode.CONTROLLER

func _handle_movement(delta):
	var move_vec = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		move_vec.x = 1
	if Input.is_action_pressed("move_left"):
		move_vec.x = -1
	if Input.is_action_pressed("move_up"):
		move_vec.y = -1
	if Input.is_action_pressed("move_down"):
		move_vec.y = 1
		
	move_vec *= move_vec_multiplier
		
	if move_vec != Vector2.ZERO and last_move_vec == Vector2.ZERO:
		animated_sprite.play("walking")
		footsteps_timer.autostart = true
		footsteps_timer.start()
		footsteps_particles.emitting = true
		step_particles.emitting = true
	elif move_vec == Vector2.ZERO and last_move_vec != Vector2.ZERO and move_vec_multiplier != Vector2.ZERO:
		animated_sprite.play("idle")
		footsteps_timer.autostart = false
		footsteps_timer.stop()
		footsteps_particles.emitting = false
		step_particles.emitting = false

	if move_vec.x > 0:
		animated_sprite.flip_h = false
	elif move_vec.x < 0:
		animated_sprite.flip_h = true
	
	if _controller_action_area:
		if move_vec != Vector2.ZERO:
			_position_action_area_controller(move_vec)
	else:
		_position_action_area_mouse(move_vec)
	
	var input_strength = Vector2(
		Input.get_action_strength("move_left") + Input.get_action_strength("move_right"),
		Input.get_action_strength("move_down") + Input.get_action_strength("move_up")
	)
	
	move_and_collide((move_vec * speed) * input_strength)

	last_move_vec = move_vec

func _position_action_area_controller(move_vec: Vector2):
	var base_position = dirt_tilemap_path.map_to_world(
		dirt_tilemap_path.world_to_map(position)
	)
	
	var shape_extents = action_area.get_node("CollisionShape2D").shape.extents.ceil()
	
	base_position += shape_extents
	base_position += (move_vec * (shape_extents * 2))
	base_position -= move_vec
	
	action_area.global_position = base_position
	hovered_tile = dirt_tilemap_path.world_to_map(base_position) + move_vec
	
func _position_action_area_mouse(move_vec: Vector2):
	var base_position = dirt_tilemap_path.map_to_world(
		dirt_tilemap_path.world_to_map(get_global_mouse_position())
	)
	
	var shape_extents = action_area.get_node("CollisionShape2D").shape.extents.ceil()
	
	base_position += shape_extents
	
	action_area.global_position = base_position
	
	hovered_tile = dirt_tilemap_path.world_to_map(base_position)

func _check_under_action_area():
	var areas = action_area.get_overlapping_areas()
	
	for area in areas:
		if !(area in last_areas):
			if area and area.has_method("on_action_hover"):
				area.on_action_hover()
	
	for area in last_areas:
		if !(area in areas):
			if area and area.has_method("on_action_leave"):
				area.on_action_leave()
	
	var bodies = action_area.get_overlapping_bodies()
	
	for body in bodies:
		if !(body in last_bodies):
			if body and body.has_method("on_action_hover"):
				body.on_action_hover()
	
	for body in last_bodies:
		if !(body in bodies):
			if body and body.has_method("on_action_leave"):
				body.on_action_leave()
	
	last_areas = areas
	last_bodies = bodies
	
	# we only care about canceling using, hovers are fine
	if global_position.distance_to(action_area.global_position) > max_action_distance:
		action_area.set_cant_use()
		return
		
	for i in bodies:
		if i.has_method("use"):
			action_area.set_can_use()
			return
	
	for i in areas:
		if i.has_method("use"):
			action_area.set_can_use()
			return

	action_area.set_default()

func _handle_use_and_has_pending_tower():
	if !_current_tower_purchase.can_place():
		bad_action_player.play()
		event_manager.new_message(
			"Can't place tower there",
			Constants.EventLevel.WARNING
		)
		return

	tools_ui.purchase_done()
	var pos = action_area.global_position
	action_area.remove_child(_current_tower_purchase)
	# parent should be world layering, which is what the tower should live on
	get_parent().add_child(_current_tower_purchase)
	_current_tower_purchase.global_position = pos
	_current_tower_purchase.purchase()
	
	# remove the currency from the player's wallet
	game_manager.get_farm_manager().remove_lunar_rocks(
		_current_tower_purchase.value
	)
	_current_tower_purchase = null

func _cancel_current_tower():
	_current_tower_purchase.queue_free()
	_current_tower_purchase = null

func _unhandled_input(event):
	# get rid of the current selection!
	if event.is_action_pressed("cancel_selection") and _current_tower_purchase:
		_current_tower_purchase.queue_free()

	# gross
	var action_used = (
		event.is_action_pressed("use") || 
		(
			!_controller_action_area and 
			event is InputEventMouseButton and 
			event.button_index == 1 and
			event.pressed
		)
	)

	if action_used:
		if !action_area.can_use:
			bad_action_player.play()
			event_manager.new_message(
				"Target out of reach",
				Constants.EventLevel.WARNING
			)
			return

		if _current_tower_purchase:
			_handle_use_and_has_pending_tower()
			return
		
		var areas = action_area.get_overlapping_areas()
		var used = false
		
		# check if we need to use something in this area
		for i in areas:
			if i and i.has_method("use"):
				i.use()
				used = true
				animated_sprite.play("pickup")
				yield(animated_sprite,"animation_finished")
				animated_sprite.play("idle")
				
		var bodies = action_area.get_overlapping_bodies()
		for i in bodies:
			if i and i.has_method("use"):
				i.use()
				used = true
				animated_sprite.play("pickup")
				yield(animated_sprite,"animation_finished")
				animated_sprite.play("idle")

		# otherwise we can just till the land!
		if !used:
			if !ground_manager.is_tilled(hovered_tile):
				# cache tile since play can move mouse before animation is finished and it'll still place
				var to_till = hovered_tile
				animated_sprite.play("till")
				move_vec_multiplier = Vector2.ZERO
				yield(animated_sprite,"animation_finished")
				ground_manager.till_dirt(to_till)
				animated_sprite.play("idle")
				move_vec_multiplier = Vector2.ONE

func _handle_selected_tile(tile, data):
	if !data:
		return

	if !data.tilled:
		ground_manager.till_dirt(tile)

func _tower_purchase_failed():
	bad_action_player.play()
	_current_tower_purchase = null

func _initiate_tower_transaction(tower):
	if _current_tower_purchase:
		if _current_tower_scene == tower:
			_current_tower_purchase.queue_free()
			_current_tower_scene = null
			return

		_current_tower_purchase.queue_free()
		_current_tower_purchase = null
	
	_current_tower_purchase = tower.instance()
	_current_tower_scene = tower
	action_area.add_child(_current_tower_purchase)

func _physics_process(delta):
	_handle_movement(delta)
	_check_under_action_area()

func set_equipped_tool(t):
	selected_tool = t
