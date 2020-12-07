extends CanvasLayer

signal settings_initialized

const PREFS_LOCATION = "user://player.prefs"

onready var on_hover = get_node("AudioStreamPlayer")
onready var volume_options_base = get_node("MarginContainer/CenterContainer/PanelContainer/HBoxContainer/VBoxContainer/VolumeOptions")
onready var resolution = get_node("MarginContainer/CenterContainer/PanelContainer/HBoxContainer/VBoxContainer/Resolution")
onready var prefs_base = get_node("MarginContainer")
onready var options_base = get_node("MarginContainer/CenterContainer/PanelContainer/HBoxContainer/VBoxContainer")
onready var fullscreen_toggle = get_node("MarginContainer/CenterContainer/PanelContainer/HBoxContainer/VBoxContainer/FullscreenToggle")

var prefs := {
	"resolution": "1920x1080",
	"fullscreen": true,
	"audio": []
}

var _btn_option = preload("res://scenes/ui/ButtonOption.tscn")
var _volume_option = preload("res://scenes/ui/SoundOption.tscn")

var _resolution_options := [
	"1280x720",
	"1920x1080",
	"2560x1440"
]

func new_button(txt: String, noderef, function, args := []):
	var new_option = _btn_option.instance()
	
	options_base.add_child(new_option)
	
	new_option.set_text(txt)
	new_option.on_press(noderef, function, args)
	
	prefs_base.connect("visibility_changed", self, "_on_visibility_changed")

func _ready():
	# loading options should be done first
	_load_cached_options()
	_set_settings_from_prefs()
	
	prefs_base.visible = false
	
	var resume = get_node("MarginContainer/CenterContainer/PanelContainer/HBoxContainer/VBoxContainer/ResumeButton")
	
	resume.connect("button_down", prefs_base, "set_visible", [ false ])
	resume.connect("mouse_entered", on_hover, "play")
	new_button("Quit", self, "_quit_game")
	
	var popup = resolution.get_popup()
	
	for i in range(0, len(_resolution_options)):
		popup.add_item(_resolution_options[i], i)

	popup.connect("id_pressed", self, "_on_resolution_chosen")
	
	fullscreen_toggle.pressed = prefs["fullscreen"]
	fullscreen_toggle.connect("mouse_entered", on_hover, "play")
	fullscreen_toggle.connect("toggled", self, "_on_fullscreen_changed")
	
	_create_volume_options()
	
	if !prefs["fullscreen"]:
		OS.window_maximized = true

	emit_signal("settings_initialized")

func _resolution_vec():
	var split=prefs["resolution"].split("x")

	return Vector2(split[0], split[1])

func _generate_default_prefs():
	var size = OS.get_screen_size()
	var prefs_base := {
		"resolution": str(int(size.x)) + "x" + str(int(size.y)),
		"audio": [],
		"fullscreen": true
	}

	for i in range(0, AudioServer.bus_count):
		prefs_base["audio"].append(
			db2linear(AudioServer.get_bus_volume_db(i))
		)
	
	return prefs_base

func _load_cached_options():
	var saved_prefs = File.new()
	if !saved_prefs.file_exists(PREFS_LOCATION):
		prefs = _generate_default_prefs()
		_write_out_prefs()
	else:
		saved_prefs.open(PREFS_LOCATION, File.READ)
		var unstructured_prefs = saved_prefs.get_as_text()
		saved_prefs.close()
		var loaded_prefs_result = JSON.parse(unstructured_prefs)
		if loaded_prefs_result.error == OK:
			prefs = loaded_prefs_result.result

func _set_settings_from_prefs(save := false):
	# set resolution
	var split_reso = prefs["resolution"].split("x")
	var width = split_reso[0]
	var height = split_reso[1]
	var resolution_vec = Vector2(width, height)
	
	OS.window_size = resolution_vec
	OS.window_fullscreen = prefs["fullscreen"]
	
	if OS.window_size == OS.get_screen_size():
		OS.window_maximized = true

	resolution.visible = !OS.window_fullscreen

	for audio_option in prefs["audio"]:
		AudioServer.set_bus_volume_db(
			audio_option,
			linear2db(prefs["audio"][audio_option])
		)
	
	if save:
		_write_out_prefs()

func _write_out_prefs():
	var saved_prefs = File.new()
	saved_prefs.open(PREFS_LOCATION, File.WRITE)
	saved_prefs.store_line(to_json(prefs))

func _on_visibility_changed():
	get_tree().paused = prefs_base.visible

func _quit_game():
	get_tree().quit(0)

func _create_volume_options():
	for i in range(0, AudioServer.bus_count):
		var instance = _volume_option.instance()
		var bus := AudioServer.get_bus_name(i)
		var current_volume = prefs["audio"][i]

		instance.bus_index = i
		instance.option_name = bus
		
		volume_options_base.add_child(instance)

		instance.set_value(current_volume)
		instance.connect("changed", self, "_cache_volume_setting", [ i ])

func _cache_volume_setting(val, idx):
	prefs["audio"][idx] = val
	
	_set_settings_from_prefs(true)

func _on_fullscreen_changed(value):
	prefs["fullscreen"] = value
	
	_set_settings_from_prefs(true)

func _on_resolution_chosen(id):
	prefs["resolution"] = _resolution_options[id]
	
	_set_settings_from_prefs(true)
	
func _center_window():
	OS.set_window_position(
		OS.get_screen_size()*0.5 - 
		OS.window_size*0.5
	)

func _unhandled_input(event):
	if event.is_action_pressed("cancel_selection"):
		if !prefs_base.visible:
			prefs_base.visible = true
		else:
			prefs_base.visible = false
		
