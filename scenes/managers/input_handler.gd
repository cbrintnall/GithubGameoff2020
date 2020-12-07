extends Node2D

signal input_mode_changed(mode)

onready var input_notification_base = get_node("InputChangedNotification/MarginContainer")
onready var controller_disconnected_dialogue = input_notification_base.get_node("CenterContainer/MarginContainer/MarginContainer/ControllerDisconnected")
onready var set_keyboard_btn = controller_disconnected_dialogue.get_node("CenterContainer/Button")
onready var game_manager = get_node("/root/GameManager")

var input_mode = Constants.InputMode.KEYBOARD
var _focused_controller := -1
var _controller_disconnected := false

# remove these when switching to the other mode, them when we switch to our mode.
# this makes it so controller inputs won't work during keyboard and vice versa
var _input_map := {
	Constants.InputMode.KEYBOARD: {},
	Constants.InputMode.CONTROLLER: {}
}

func _ready():
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	# figure out what input mode we should start in
	_sync_input_mode()
	# pull down the action map from project settings
	_sync_input_map()
	# wipe out all keybindings so we have the correct one
	_wipe_action_map()
	# load the correct map into the actions
	_load_map_for(input_mode)

	input_notification_base.visible = false
	controller_disconnected_dialogue.visible = false
	set_keyboard_btn.connect("button_down", self, "_on_controller_disconnect_press_btn")

func _on_controller_disconnect_press_btn():
	input_notification_base.visible = false
	controller_disconnected_dialogue.visible = false
	get_tree().paused = false
	_controller_disconnected = false
	_set_to_keyboard()

# probably don't need this anymore?
func _notify_input_changed(mode):
	var message = "Input changed to {input}".format({
		"input": "controller" if mode == Constants.InputMode.CONTROLLER else "keyboard"
	})
	
	game_manager.get_event_manager().new_message(message, Constants.EventLevel.META)
	
# wipes out all current events (not the actions themselves!)
func _wipe_action_map():
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)

func _load_map_for(input_mode):
	# load all actions for the current input mode (controller or keyboard)
	for action in _input_map[input_mode]:
		for event in _input_map[input_mode][action]:
			InputMap.action_add_event(action, event)

func _sync_input_map():
	for action in InputMap.get_actions():
		for event in InputMap.get_action_list(action):
			var is_controller = (
				event is InputEventJoypadMotion or
				event is InputEventJoypadButton
			)
			
			var is_keyboard = (
				event is InputEventKey or
				event is InputEventMouseButton
			)
			
			var input_key = Constants.InputMode.KEYBOARD if is_keyboard else Constants.InputMode.CONTROLLER
			
			if !(action in _input_map[input_key]):
				_input_map[input_key][action] = [] 
			
			_input_map[input_key][action].append(event)

func _sync_input_mode():
	if len(Input.get_connected_joypads()) > 0:
		_set_to_controller(Input.get_connected_joypads()[0])
	else:
		_set_to_keyboard()

func _set_to_controller(device):
	# ignore if we're already in this mode
	if input_mode == Constants.InputMode.CONTROLLER:
		return

	input_mode = Constants.InputMode.CONTROLLER
	emit_signal("input_mode_changed", input_mode)
	_focused_controller = device
	_load_map_for(input_mode)
	
func _set_to_keyboard():
	# ignore if we're already in this mode
	if input_mode == Constants.InputMode.KEYBOARD:
		return

	input_mode = Constants.InputMode.KEYBOARD
	emit_signal("input_mode_changed", input_mode)
	_load_map_for(input_mode)

func _on_joy_connection_changed(device_idx: int, connected: bool):
	var used_controller_disconnected = (
		input_mode == Constants.InputMode.CONTROLLER and 
		device_idx == _focused_controller and 
		!connected
	)
	
	# whenever the device disconnects..
	if used_controller_disconnected:
		input_notification_base.visible = true
		controller_disconnected_dialogue.visible = true
		get_tree().paused = true
		_controller_disconnected = true
	# if a controller connected and it we are currently using keyboard
	elif connected and input_mode == Constants.InputMode.KEYBOARD:
		_set_to_controller(device_idx)

	if _controller_disconnected and connected:
		_controller_disconnected = false
		input_notification_base.visible = false
		controller_disconnected_dialogue.visible = false
		get_tree().paused = false

func _input(event):
	# set controls to keyboard if we get input from that or mouse, and we're not already in that mode
	if input_mode != Constants.InputMode.KEYBOARD and (event is InputEventKey or event is InputEventMouseButton):
		_set_to_keyboard()
	# set controls to controller if not already in controller mode and we get input from one
	elif input_mode != Constants.InputMode.CONTROLLER and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		_set_to_controller(event.device)
