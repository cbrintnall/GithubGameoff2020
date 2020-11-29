extends Sprite

signal do_pulse(energy)
signal broken

export(Vector2) var light_size = Vector2(32, 32)
export(float) var max_pulse
export(float) var min_pulse

onready var beam_audio = get_node("Moonlight/AudioStreamPlayer2D")
onready var beam_particles = get_node("Moonlight/Particles2D")
onready var beam_light = get_node("Moonlight/BeamLight")
onready var beam_tween = get_node("Moonlight/Tween")
onready var game_manager = get_node("/root/GameManager")
onready var player_prefs = game_manager.get_player_prefs()
onready var ground_manager = game_manager.get_ground_manager()
onready var health_bar := get_node("UIBase/VBoxContainer/HealthBar")
onready var energy_bar := get_node("UIBase/VBoxContainer/EnergyBar")
onready var timer: Timer = get_node("Timer")
onready var particles: CPUParticles2D = get_node("CPUParticles2D")

var max_energy := 1000
var current_energy := max_energy
var max_health := 100
var health := max_health
var max_distance_in_tiles = 5
var next_energy_emitted := 100

var _path_effect := preload("res://scenes/towers/lunar_pool/path_effect.tscn")

func consume_energy():
	pass
	
func gain_energy(energy: float):
	current_energy = clamp(current_energy + energy, 0.0, max_energy)
	energy_bar.value = current_energy

func set_energy(energy: float):
	current_energy = clamp(energy, 0.0, max_energy)
	energy_bar.value = current_energy

func take_damage(amt: int):
	health -= amt
	
	health_bar.value = health
	
	if health <= 0:
		emit_signal("broken")

func _ready():
	beam_light.visible = false
	beam_particles.emitting = false

	timer.connect("timeout", self, "_pulse")
	game_manager.get_farm_manager().connect("night", self, "_on_night")
	game_manager.get_farm_manager().connect("day", self, "_on_day")

	health_bar.max_value = max_health
	health_bar.min_value = 0

	take_damage(0)
	
	energy_bar.max_value = max_energy
	energy_bar.min_value = 0
	energy_bar.value = max_energy

	# do first pulse
	_pulse()
	
	player_prefs.register_command("moon", funcref(self, "_handle_command"))
	
func _handle_command(args: Array):
	match args:
		[ "energy", var amount ]:
			var amt = int(amount)
			
			set_energy(amt)
	
func _on_day():
	var screen_size = OS.get_screen_size()
	var duration := 1.0

	beam_particles.emitting = false
	beam_audio.stop()
	
	beam_tween.interpolate_property(
		beam_light,
		"global_position",
		beam_light.global_position,
		beam_light.global_position - Vector2(0, screen_size.y/4),
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	
	beam_tween.interpolate_property(
		beam_audio,
		"volume_db",
		linear2db(1),
		linear2db(0),
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	
	beam_tween.interpolate_method(
		self,
		"set_energy",
		current_energy,
		max_energy,
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_IN_OUT
	)
	
	beam_tween.start()
	yield(beam_tween,"tween_all_completed")
	beam_light.visible = false
	game_manager.get_event_manager().new_message("The moon's energy has been restored!", Constants.EventLevel.GOOD)

func _on_night():
	var screen_size = OS.get_screen_size()
	var duration := 1.0

	beam_audio.play()
	beam_light.visible = true
	beam_light.scale.y = (screen_size.y/2) / beam_light.texture.get_size().y
	beam_light.global_position = Vector2(beam_light.global_position.x, beam_light.global_position.y-screen_size.y/2)
	
	beam_tween.interpolate_property(
		beam_light,
		"global_position",
		beam_light.global_position,
		beam_light.global_position + Vector2(0, screen_size.y/4),
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	
	beam_tween.interpolate_property(
		beam_audio,
		"volume_db",
		linear2db(0),
		linear2db(1),
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	
	beam_tween.start()
	yield(beam_tween,"tween_all_completed")
	beam_particles.emitting = true

func _path_finished(amount, location, path):
	# notify location should gain energy since path is at end
	location.give_energy(amount)
	# true so it frees itself
	path.fade_out(true)

func _send_energy_to(to, amount):
	var new_path = _path_effect.instance()
	add_child(new_path)

	# cap the amount we send to the amount we can actually store
	var sending = amount
	if sending + to.current_energy > to.max_energy_stored:
		sending = to.max_energy_stored - to.current_energy
	
	current_energy -= sending
	energy_bar.value = current_energy
	
	# set the new path to hit the tilled land, then free itself.
	new_path.speed = 0.01
	new_path.set_scale_random(0.1)
	new_path.set_amount(10)
	new_path.set_do_lerp(true)
	new_path.set_looping(false)
	new_path.set_particle_size(0.05)
	new_path.set_target(to)
	new_path.connect(
		"path_done", 
		self, 
		"_path_finished", 
		[ next_energy_emitted, to, new_path ]
	)

func _pulse():
	# TODO: should emit a warning event here
	if current_energy < next_energy_emitted:
		return
	
	# send energy to all tilled land
	for land in ground_manager.get_tilled_land():
		# only send energy if a plant is growing
		if !land.growing_plant:
			continue

		# if we no longer have enough energy to send, just break.
		if current_energy < next_energy_emitted:
			break
			
		# don't send energy if it's full, this would waste it
		if land.current_energy >= land.max_energy_stored:
			continue

		_send_energy_to(land, next_energy_emitted)

	# generate the next amount of energy we'll send
	next_energy_emitted = rand_range(min_pulse, max_pulse)
	timer.start()
