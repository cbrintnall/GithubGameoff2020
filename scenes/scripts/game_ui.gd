extends CanvasLayer

class_name RightPanel

"""
the goal with this panel is to allow different events to trigger different
displays within it. various children containers will handle this logic.
"""

onready var event_bus = get_node("/root/EventBusManager")
onready var base = get_node("MarginContainer")
onready var close_button = get_node("MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/MarginContainer/CloseButton")

# panels
onready var tower_panel = get_node("MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/TowerDisplay")

func _ready():
	close_button.connect("button_down", base, "set_visible", [ false ])
	event_bus.connect("new_event", self, "_on_bus_event")
	base.visible = false
	
	tower_panel.connect("close", base, "set_visible", [ false ])
	
func _on_bus_event(event: int, data := {}):
	match event:
		Constants.BusEvents.TOWER_SELECTED:
			var tower = data.get("tower")

			if tower:
				tower_panel.set_tower(tower)

			base.visible = true
