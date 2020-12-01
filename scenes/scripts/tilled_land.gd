extends Area2D

signal done_growing

export(int) var max_energy_stored := 100
export(AudioStreamSample) var harvest_sound
export(AudioStreamSample) var plant_sound

# energy gained per tick
const decr_amt = 10.0

onready var player = get_node("AudioStreamPlayer2D")
onready var energy_particles = get_node("CPUParticles2D")
onready var seed_chooser = get_node("SeedChooser")
onready var game_manager = get_node("/root/GameManager")
onready var growing_sprite = get_node("GrowingPlant")
onready var energy_notification_tween = get_node("Tween")
onready var energy_notification_text = get_node("Node2D/Label")
onready var label_parent = get_node("Node2D")

var tween_duration = 1.0
var growing_plant: GrowingPlant
var plant_done: bool
var current_energy: float
var current_progress = 0.0

var _exploder := preload("res://scenes/scripts/item_exploder.gd")
var _fading_out := false

func _ready():
	growing_sprite.playing = false
	growing_sprite.visible = false

	game_manager.get_node("GroundManager").connect("do_tick", self, "_on_ground_tick")

	seed_chooser.visible = false
	seed_chooser.connect("chose", self, "_on_choose_seed")

#hijack notification tween since we wont need it anymore
func _destroy_plot():
	_fading_out=true
	energy_notification_tween.interpolate_property(
		self,
		"modulate",
		Color.white,
		Color.transparent,
		1.0,
		Tween.TRANS_CUBIC,
		Tween.EASE_IN
	)
	energy_notification_tween.start()
	yield(energy_notification_tween,"tween_all_completed")
	queue_free()

func _get_seeds_in_players_inventory() -> Array:
	var seeds := []
	var player = game_manager.get_player()
	
	for item in player.inventory.get_items():
		if item.plant:
			seeds.append(item)
			
	return seeds

func _on_choose_seed(item):
	game_manager.get_player().inventory.remove_item(item)
	set_growing(item.plant)
	
	game_manager.event_manager.new_message("Planted " + item.item_name)

func _energy_notification(incr: bool, amt: float):
	var prefix = "+ " if incr else "- "
	energy_notification_text.text = prefix + str(amt)
	energy_notification_tween.interpolate_property(
		label_parent,
		"position",
		Vector2.ZERO,
		Vector2.UP * 5,
		tween_duration,
		Tween.TRANS_LINEAR
	)
	energy_notification_tween.interpolate_property(
		label_parent,
		"modulate",
		Color.white,
		Color.transparent,
		tween_duration,
		Tween.TRANS_LINEAR
	)
	energy_notification_tween.start()

func _on_ground_tick():
	# dont care about ticks if nothing is growing on this plot!
	# or if the plant has already finished growing :)
	if !growing_plant || current_progress >= growing_plant.required_energy || current_energy <= 0.0 || plant_done:
		return
	
	current_energy = clamp(current_energy-decr_amt, 0, 100)
	current_progress = clamp(current_progress+decr_amt, 0, growing_plant.required_energy)
	
	_energy_notification(false, decr_amt)
	
	# interpolate the frames over the lifetime growth of the plant
	var frame_count = growing_sprite.frames.get_frame_count("default")
	var ratio = current_progress/growing_plant.required_energy
	var frame = ceil(lerp(frame_count-1, 0, ratio))
	
	growing_sprite.frame = frame
	
	if current_progress >= growing_plant.required_energy:
		_on_finished_growing()
		
func _on_finished_growing():
	energy_particles.color = Color.limegreen
	growing_sprite.frame = 0
	growing_sprite.playing = false
	plant_done = true

	emit_signal("done_growing")

func on_action_hover():
	if !growing_plant and !_fading_out:
		_enable_seed_menu()
	
func on_action_leave():
	seed_chooser.disable()

func _enable_seed_menu():
	seed_chooser.set_options(_get_seeds_in_players_inventory())
	seed_chooser.enable()

func _do_harvest():
	var items_explosion := _exploder.new()
	get_tree().root.add_child(items_explosion)
	
	items_explosion.z_index = z_index + 1
	items_explosion.global_position = global_position
	items_explosion.set_items([ growing_plant.finished_plant ])
	items_explosion.explode()
	
	growing_plant = null
	growing_sprite.visible = false
	energy_particles.color = Color.white
	player.stream = harvest_sound
	player.play()
	_destroy_plot()

func done_growing():
	return growing_plant and current_progress >= growing_plant.required_energy

func use():
	if !_fading_out and done_growing():
		_do_harvest()
		return
	elif growing_plant:
		return
		
	seed_chooser.selected()

func give_energy(amt: float):
	var initial_energy = current_energy
	current_energy = clamp(current_energy+amt, 0, 100)
	var energy_gained = current_energy - initial_energy
	
	var amount = lerp(0, 10, current_energy/100)
	
	energy_particles.visible = amount > 0
	
	if amount != energy_particles.amount:
		energy_particles.amount = clamp(lerp(0, 10, current_energy/100), 1, 10)
	
	if energy_gained > 0:
		_energy_notification(true, energy_gained)

func set_growing(plant: GrowingPlant):
	plant_done = false
	growing_plant = plant
	growing_sprite.frames = plant.grow_frames
	growing_sprite.visible = true
	# set to final frame, since our frames are all backwards lol
	growing_sprite.frame = growing_sprite.frames.get_frame_count("default")-1
	current_progress = 0.0
	energy_particles.color = Color.aliceblue
	player.stream = plant_sound
	player.play()
	seed_chooser.disable()
