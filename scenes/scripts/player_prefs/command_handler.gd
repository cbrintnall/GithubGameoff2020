extends CanvasLayer

onready var input = get_node("CenterContainer/MarginContainer/PanelContainer/LineEdit")
onready var input_base = get_node("CenterContainer")

var commands := {}

func _ready():
	input.connect("text_entered", self, "_on_text_entered")
	
	input_base.connect("visibility_changed", self, "_on_visibility_changed")
	input_base.visible = false

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_F1:
			input_base.visible = !input_base.visible
		elif input_base.visible and event.pressed and event.scancode == KEY_ESCAPE:
			input_base.visible = false

func _on_visibility_changed():
	if input_base.visible:
		input.grab_focus()
		get_tree().paused = true
	else:
		get_tree().paused = false

func _on_text_entered(text):
	input_base.visible = false
	input.text = ""
	_handle_command(text)
	
func _handle_command(command: String):
	var cmd = command.split(' ')

	if cmd[0] in commands:
		var copy := []
		for i in cmd:
			copy.append(i)
		commands[cmd[0]].call_func(copy.slice(1, copy.size()-1))
