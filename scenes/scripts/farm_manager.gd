extends Node2D

signal night
signal day
signal shipment_time

const tween_duration := 3.0

onready var timer = get_node("DayCycle/Timer")
onready var day_canvas = get_node("DayCycle/CanvasModulate")
onready var transition_tween = get_node("DayCycle/Tween")
onready var rock_increase_tween = get_node("CanvasLayer/Tween")
onready var lunar_rock_audio = get_node("CanvasLayer/LunarRockGained")
onready var time_label = get_node("CanvasLayer/VBoxContainer/NinePatchRect2/MarginContainer/Label")
onready var clock_base = get_node("CanvasLayer/VBoxContainer/NinePatchRect2")
onready var lunar_rock_label = get_node("CanvasLayer/VBoxContainer/MarginContainer/MarginContainer/HBoxContainer/Label")
onready var moonlight = get_node("MoonLight")

export(int) var moonlight_min_x_offset = -500
export(int) var moonlight_max_x_offset = 500
export(int) var lunar_rock_gain_sound_divisor := 1
export(Color) var day_color
export(Color) var night_color
# in hours
export(int) var day_breakpoint
export(int) var night_breakpoint
export(int) var shipment_buffer_time = 2
export(float) var transition_time

var night_unit_time := 0.0
var day_unit_time := 0.0

var lunar_rock_amt := 0
var current_lunar_rocks := 0

var day: int
# start the game at 7 AM!
# TODO: change back to 7 am
var hours := 7
var minutes: int

func is_day() -> bool:
	return hours > day_breakpoint and hours < night_breakpoint

func get_current_time():
	return {
		"day": day,
		"hours": hours,
		"minutes": minutes
	}

func to_text(amt):
	var true_amt := int(floor(amt))
	
	if (true_amt % lunar_rock_gain_sound_divisor) == 0:
		if lunar_rock_audio.playing:
			lunar_rock_audio.stop()

		lunar_rock_audio.play()

	lunar_rock_label.text = str(true_amt)

func _sync_lunar_rock_to_label(by := 0):
	if by:
		rock_increase_tween.interpolate_method(
			self,
			"to_text",
			current_lunar_rocks-by,
			current_lunar_rocks,
			tween_duration,
			Tween.TRANS_EXPO,
			Tween.EASE_IN
		)
		rock_increase_tween.interpolate_method(
			lunar_rock_audio,
			"set_pitch_scale",
			.75,
			1.5,
			tween_duration,
			Tween.TRANS_EXPO,
			Tween.EASE_IN
		)
		rock_increase_tween.start()
		yield(rock_increase_tween,"tween_all_completed")
		lunar_rock_audio.set_pitch_scale(.75)
	else:
		lunar_rock_label.text = str(current_lunar_rocks)

func add_lunar_rocks(amt: int):
	current_lunar_rocks += amt
	
	_sync_lunar_rock_to_label(amt)
	
func remove_lunar_rocks(amt: int):
	current_lunar_rocks = int(clamp(current_lunar_rocks-amt, 0, INF))
	
	_sync_lunar_rock_to_label()
	
func _set_to_appropriate_time():
	if is_day():
		_transition_day()
	else:
		_transition_night()
	
func _transition_day():
	_transition_to_color(day_color)
	emit_signal("day")
	
func _transition_night():
	_transition_to_color(night_color)
	emit_signal("night")

func _transition_to_color(c: Color):
	transition_tween.interpolate_property(
		day_canvas,
		"color",
		day_canvas.color,
		c,
		transition_time,
		Tween.TRANS_LINEAR
	)
	
	transition_tween.start()

func _ready():
	timer.connect("timeout", self, "_on_timeout")
	clock_base.visible = true
	
	_set_to_appropriate_time()
	_sync_lunar_rock_to_label()
	
	# we set it to -1 in editor to hide it, this makes sure it's always there :)
	get_node("CanvasLayer").layer = 1
	
	var prefs = get_node("/root/GameManager").get_player_prefs()
	
	prefs.register_command("coins", funcref(self, "_on_coins"))
	prefs.register_command("time", funcref(self, "_on_time"))

func _on_time(args):
	match args:
		["hour", "set", var to]:
			hours = int(to)
		["minute", "set", var to]:
			minutes = int(to)
		["set", "night"]:
			hours = night_breakpoint-1
			minutes = 59
		["set", "day"]:
			hours = day_breakpoint-1
			minutes = 59

func _on_coins(args):
	match args:
		["add", var amount]:
			add_lunar_rocks(int(amount))
		["remove", var amount]:
			remove_lunar_rocks(int(amount))

func _process(delta):
	if !is_day():
		pass

func _on_timeout():
	minutes += 1
	
	if minutes > 59:
		minutes = 0
		hours += 1
		
		if hours == day_breakpoint:
			_transition_day()
			
		if hours == night_breakpoint:
			_transition_night()
			
		if hours == (night_breakpoint - shipment_buffer_time):
			emit_signal("shipment_time")
		
		var minute_lerp = inverse_lerp(0, 59, minutes)
		
		if hours >= night_breakpoint:
			night_unit_time = clamp(inverse_lerp(night_breakpoint, 24, hours), 0.0, 0.4)
		if hours >= 0 and hours < day_breakpoint:
			night_unit_time = clamp(inverse_lerp(0, day_breakpoint, hours), .4, 1.0)
	
	if hours > 23:
		hours = 0
		day += 1
		
	var time_hours = str(hours) if hours >= 10 else "0" + str(hours)
	var time_minutes = str(minutes) if minutes >= 10 else "0" + str(minutes)

	time_label.text = "{hours}:{minutes}".format({ "hours": time_hours, "minutes": time_minutes })
