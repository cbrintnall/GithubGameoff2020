extends Node2D

class_name MouseManager

onready var game_manager = get_node("/root/GameManager")
onready var area = get_node("Area2D")

func _ready():
	connect("area_entered", self, "_on_area_entered")
	connect("area_exited", self, "_on_area_exited")

func _on_area_entered(area):
	pass
	
func _on_area_exited(area):
	pass

func _process(delta):
#	position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("activate"):
		pass
#		_handle_selected_tile(hovered_tile, ground_manager.get_data_at(hovered_tile))
