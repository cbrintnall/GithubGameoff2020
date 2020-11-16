extends KinematicBody2D

enum Tool {
	HOE,
	AXE,
	PICKAXE
}

export(float) var speed = 10.0
export(Vector2) var tilemap_size = Vector2(16, 16)
export(Color) var valid_selection_color = Color.green
export(Color) var invalid_selection_color = Color.red
export(NodePath) onready var dirt_tilemap_path = get_node(dirt_tilemap_path)
export(NodePath) onready var ground_manager = get_node(ground_manager)

onready var game_manager = get_node("/root/GameManager")
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

var _current_tower_scene: PackedScene
var _current_tower_purchase

func _ready():
	get_node("/root/GameManager").set_current_camera(get_node("Camera2D"))
	get_node("ToolsUi").connect("tower_selected", self, "_initiate_tower_transaction")
	set_equipped_tool(Tool.HOE)
	
	footsteps_timer.connect("timeout", get_node("footsteps/audio"), "play")
	
	action_area.visible = true

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
	
	if move_vec != Vector2.ZERO:
		var base_position = dirt_tilemap_path.map_to_world(
			dirt_tilemap_path.world_to_map(position)
		)
		
		var shape_extents = action_area.get_node("CollisionShape2D").shape.extents.ceil()
		
		base_position += shape_extents
		base_position += (move_vec * (shape_extents * 2))
		base_position -= move_vec
		
		action_area.global_position = base_position
		hovered_tile = dirt_tilemap_path.world_to_map(position) + move_vec
		
	move_and_collide(move_vec * speed)

	last_move_vec = move_vec

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
	
	last_areas = areas
	
	for i in areas:
		if i.has_method("use"):
			action_area.set_can_use()
			return
			
	action_area.set_default()

func _handle_use_and_has_pending_tower():
	if !_current_tower_purchase.can_place():
		bad_action_player.play()
		return

	var pos = action_area.global_position
	action_area.remove_child(_current_tower_purchase)
	get_tree().root.add_child(_current_tower_purchase)
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

func _input(event):
	# get rid of the current selection!
	if event.is_action_pressed("cancel_selection") and _current_tower_purchase:
		_current_tower_purchase.queue_free()

	if event.is_action_pressed("use"):
		if _current_tower_purchase:
			_handle_use_and_has_pending_tower()
			return
		
		var areas = action_area.get_overlapping_areas()
		
		# check if we need to use something in this area
		for i in areas:
			if i and i.has_method("use"):
				i.use()
				animated_sprite.play("pickup")
				yield(animated_sprite,"animation_finished")
				animated_sprite.play("idle")

		# otherwise we can just till the land!
		if len(areas) == 0:
			if !ground_manager.is_tilled(hovered_tile):
				animated_sprite.play("till")
				move_vec_multiplier = Vector2.ZERO
				yield(animated_sprite,"animation_finished")
				ground_manager.till_dirt(hovered_tile)
				animated_sprite.play("idle")
				move_vec_multiplier = Vector2.ONE

func _handle_selected_tile(tile, data):
	if !data:
		return

	if !data.tilled:
		ground_manager.till_dirt(tile)

func _initiate_tower_transaction(tower):
	if tower.instance().value > game_manager.get_farm_manager().current_lunar_rocks:
		bad_action_player.play()
		_current_tower_purchase = null
		return
	
	# remove selection if they hit the same tower again
	if _current_tower_scene == tower and _current_tower_purchase:
		_current_tower_purchase.queue_free()

	# if we are already purchasing, just return, we don't need another ya goose!
	if _current_tower_purchase:
		return
	
	_current_tower_purchase = tower.instance()
	_current_tower_scene = tower
	action_area.add_child(_current_tower_purchase)

func _physics_process(delta):
	_handle_movement(delta)
	_check_under_action_area()

func set_equipped_tool(t):
	selected_tool = t
