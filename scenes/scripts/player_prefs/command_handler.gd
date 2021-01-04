extends CanvasLayer

onready var base_label = get_node("CenterContainer/VBoxContainer/PanelContainer/VBoxContainer/Label")
onready var output_container = get_node("CenterContainer/VBoxContainer/PanelContainer/VBoxContainer")
onready var input = get_node("CenterContainer/VBoxContainer/MarginContainer/PanelContainer/LineEdit")
onready var input_base = get_node("CenterContainer")

var commands := {}
var line_max = 20

# text: text to output
# level: the log level, really provides coloring for now
# clear: if we should clear if we exceed the line count max
func write_output(
	text: String, 
	level = Constants.LogLevel.INFO,
	clear := true 
):
	if !output_container.visible:
		output_container.visible = true

	var label = base_label.duplicate()
	
	label.visible = true
	label.text = text
	
	output_container.add_child(label)
	
	if clear and output_container.get_child_count() > line_max:
		for i in range(1, output_container.get_child_count() - line_max):
			var child = output_container.get_child(i)
			
			child.queue_free()

func clear():
	for i in range(1, output_container.get_child_count()):
		var child = output_container.get_child(i)
		
		child.queue_free()
		
	output_container.visible = false

func _ready():
	base_label.visible = false

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
	input.text = ""
	_handle_command(text)

func _handle_command(command: String):
	var cmd = command.split(' ')

	if cmd[0] in commands:
		var copy := []
		for i in cmd:
			copy.append(i)
		commands[cmd[0]].call_func(copy.slice(1, copy.size()-1))

