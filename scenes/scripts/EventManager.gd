extends CanvasLayer

onready var base_label = get_node("Control/VBoxContainer/BaseLabel")
onready var events_base = get_node("Control/VBoxContainer")

const event_limit = 15

func new_message(message: String):
	var new_label = base_label.duplicate()
	
	new_label.visible = true
	new_label.text = message
	
	events_base.add_child(new_label)
	
	# free the latest event if we have too many, don't free position 0, thats our base
	if events_base.get_child_count() > event_limit:
		events_base.get_child(1).queue_free()
